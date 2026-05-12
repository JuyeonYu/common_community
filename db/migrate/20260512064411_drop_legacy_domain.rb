class DropLegacyDomain < ActiveRecord::Migration[8.1]
  # 커뮤니티 게시판 도메인 일괄 폐기 (Phase A 피벗).
  # action_text / active_storage / sessions / users / notifications / push_subscriptions 는 유지.
  def up
    drop_table :likes, if_exists: true
    drop_table :post_tags, if_exists: true
    drop_table :reports, if_exists: true
    drop_table :comments, if_exists: true
    drop_table :posts, if_exists: true
    drop_table :tags, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
