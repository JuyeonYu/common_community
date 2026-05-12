class CreateConnectRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :connect_requests do |t|
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :target,    null: false, foreign_key: { to_table: :users }
      t.string  :gen_week, null: false              # "2026W21" 등 ISO 주 단위
      t.integer :status,   null: false, default: 0  # 0:pending 1:accepted 2:rejected 3:cancelled 4:expired
      t.timestamps
    end
    add_index :connect_requests, [ :requester_id, :gen_week ]
    add_index :connect_requests, [ :target_id, :gen_week ]
    add_index :connect_requests, [ :status, :created_at ]
  end
end
