class CreateConversationsMessagesBlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :user_one, null: false, foreign_key: { to_table: :users }
      t.references :user_two, null: false, foreign_key: { to_table: :users }
      t.datetime   :user_one_last_read_at
      t.datetime   :user_two_last_read_at
      t.datetime   :last_message_at
      t.timestamps
      t.index [ :user_one_id, :user_two_id ], unique: true, name: "index_conversations_on_pair"
      t.index [ :user_two_id, :last_message_at ]
      t.check_constraint "user_one_id < user_two_id", name: "conversations_user_order"
    end

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text       :body
      t.integer    :status, null: false, default: 0
      t.timestamps
      t.index [ :conversation_id, :created_at ]
    end

    create_table :blocks do |t|
      t.references :blocker, null: false, foreign_key: { to_table: :users }
      t.references :blocked, null: false, foreign_key: { to_table: :users }
      t.text       :reason
      t.timestamps
      t.index [ :blocker_id, :blocked_id ], unique: true, name: "index_blocks_on_pair"
      t.check_constraint "blocker_id <> blocked_id", name: "blocks_no_self"
    end
  end
end
