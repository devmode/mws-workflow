class CreateFeedQueues < ActiveRecord::Migration
  def change
    create_table :feed_queues do | table |
      table.string :name, null: false
      table.string :feed_type, null: false
      table.integer :priority, null: false
      table.integer :batch_size, null: false
      table.string :merchant, null: false
      table.datetime :last_drain, null: true
      table.timestamps
    end
  end
end
