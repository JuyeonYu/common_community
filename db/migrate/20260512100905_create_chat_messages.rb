class CreateChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_messages do |t|
      t.references :red_connect, null: false, foreign_key: true
      t.references :sender,      null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.timestamps
    end
    add_index :chat_messages, [ :red_connect_id, :created_at ]
  end
end
