class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.text :user_message, null: false
      t.text :ai_response, null: false
      t.string :session_id, null: false
      t.datetime :timestamp, null: false
      
      t.timestamps
    end
    
    # Add indexes for better performance
    add_index :conversations, :session_id
    add_index :conversations, :timestamp
    add_index :conversations, :created_at
  end
end
