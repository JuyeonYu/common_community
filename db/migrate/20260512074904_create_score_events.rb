class CreateScoreEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :score_events do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :delta, null: false           # 음수/양수 모두 가능
      t.integer :reason, null: false          # enum
      t.references :related, polymorphic: true # Notification/Downvote/RedConnect 등
      t.text :memo                            # admin 조정 시 사유

      t.timestamps
    end
    add_index :score_events, [ :user_id, :created_at ]
  end
end
