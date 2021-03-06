require 'mws'

class SubmitFeed < Job

  def initialize(options)
    @merchant = options[:merchant]
    @device = [ self.class.name.split('::').last, @merchant ].join ':'
  end

  def perform
    queue, tasks = select_queue
    return if queue.nil? or Battery.discharge(@device).nil?
    queue.last_drain = Time.now
    queue.save
    api = Mws::Apis::Feeds::TargetedApi.new Mws.connection.feeds, @merchant, queue.feed_type
    tx = api.submit(tasks)
    FeedTransaction.transaction do
      transaction = FeedTransaction.create identifier: tx.id, state: :running
      tasks.zip(tx.items) do | task, item |
        task.transaction = transaction
        task.index = item.id
        task.save
      end
    end
  end

  private

  def select_queue
    FeedQueue.merchant(@merchant).order('last_drain asc nulls first', :priority).each do | queue |
      tasks = queue.tasks.ready.order(:created_at).limit(queue.batch_size)
      return [ queue, tasks ] unless tasks.empty?
    end
    return [ nil, nil ]
  end

end