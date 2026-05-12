class AddInvitationFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    # 어느 사용자로부터 초대를 받았는가. 시드 사용자 또는 외부 초대 경로면 NULL.
    add_reference :users, :invited_by, foreign_key: { to_table: :users }, null: true

    # 초대 코드가 적용된 시점. NULL이면 비활성(잠금 화면으로 강제 이동).
    add_column :users, :invitation_accepted_at, :datetime

    # 시드 사용자 표시. true면 초대 코드 없이도 활성으로 간주.
    add_column :users, :seed, :boolean, default: false, null: false
  end
end
