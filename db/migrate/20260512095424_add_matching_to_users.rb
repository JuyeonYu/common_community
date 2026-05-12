class AddMatchingToUsers < ActiveRecord::Migration[8.1]
  def change
    # 이성 매칭 풀 참여 여부. 본인이 명시적으로 활성화해야 true.
    add_column :users, :matching_enabled, :boolean, default: false, null: false
    # 최초 활성화 시점(이력용). 휴식 후 재활성화 시 갱신.
    add_column :users, :matching_activated_at, :datetime
  end
end
