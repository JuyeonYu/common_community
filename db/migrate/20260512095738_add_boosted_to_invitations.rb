class AddBoostedToInvitations < ActiveRecord::Migration[8.1]
  # 강력 추천 표시. 발급자가 크레딧을 소비하여 활성화 가능.
  def change
    add_column :invitations, :boosted, :boolean, default: false, null: false
  end
end
