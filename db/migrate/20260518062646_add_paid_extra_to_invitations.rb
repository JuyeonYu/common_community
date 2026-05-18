class AddPaidExtraToInvitations < ActiveRecord::Migration[8.1]
  def change
    # 7일 무료 외 크레딧으로 추가 발급된 초대 표시 — 미가입 만료 시 50% 환급 대상.
    add_column :invitations, :paid_extra, :boolean, default: false, null: false
  end
end
