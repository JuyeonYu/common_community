class AddInviteeEmailToInvitations < ActiveRecord::Migration[8.1]
  def change
    # 초대받을 사람의 이메일. 발급 시 필수. 가입 시점에 Google OAuth 이메일과 매칭 검증.
    # 기존 row(있을 수 있음)는 admin이 별도 처리. 우선 nullable로 추가하고 검증으로 강제.
    add_column :invitations, :invitee_email, :string
    add_index  :invitations, :invitee_email
  end
end
