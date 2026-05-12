class CreateRedConnects < ActiveRecord::Migration[8.1]
  # 커넥트 성사된 1:1 채널. 채팅 메시지/UI는 Phase D-3에서 도입.
  # user_a < user_b 정렬을 모델에서 보장하여 동일 쌍 unique 보장.
  def change
    create_table :red_connects do |t|
      t.references :user_a, null: false, foreign_key: { to_table: :users }
      t.references :user_b, null: false, foreign_key: { to_table: :users }
      t.integer  :status,         null: false, default: 0 # 0:active 1:released 2:expired
      t.datetime :expires_at,     null: false
      t.string   :release_reason
      t.timestamps
    end
    add_index :red_connects, [ :user_a_id, :user_b_id ], unique: true
    add_index :red_connects, [ :user_b_id, :status ]
  end
end
