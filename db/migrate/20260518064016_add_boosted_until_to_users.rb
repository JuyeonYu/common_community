class AddBoostedUntilToUsers < ActiveRecord::Migration[8.1]
  def change
    # 프로필 우선 노출(30 크레딧, 24h) — Phase F-2-c.
    add_column :users, :boosted_until, :datetime
    add_index  :users, :boosted_until
  end
end
