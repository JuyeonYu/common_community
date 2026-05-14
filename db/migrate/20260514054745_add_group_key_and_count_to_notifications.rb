class AddGroupKeyAndCountToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :group_key, :string
    add_column :notifications, :count, :integer, default: 1, null: false

    # 미확인 그룹화 조회 — (recipient, group_key) 기준으로 read_at IS NULL인 한 건을 찾는다.
    add_index :notifications, [ :recipient_id, :group_key ],
      where: "read_at IS NULL AND group_key IS NOT NULL",
      name: "index_notifications_on_recipient_and_group_key_unread"
  end
end
