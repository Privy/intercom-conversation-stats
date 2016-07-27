class CreateConversations < ActiveRecord::Migration
  def change
    create_table :conversations do |t|
      t.json(:conversation_ids, default: [])
      t.boolean :synced, default: false, index: true
      t.timestamps
    end
  end
end
