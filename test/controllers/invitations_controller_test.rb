require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user     = users(:one)
    @inactive = users(:inactive)
    @pending  = invitations(:pending_one)
    @expired  = invitations(:expired_one)
    # inactive 사용자의 이메일을 pending invitation에 맞춰 두면 redeem 매칭이 통과한다.
    @inactive.update!(email_address: @pending.invitee_email)
  end

  # --- show (/i/:code) ---

  test "show: 비로그인 + 유효 코드 → 세션 저장 후 로그인 페이지" do
    get invite_link_path(code: @pending.code)
    assert_redirected_to new_session_path
    assert_equal @pending.code, session[:pending_invitation_code]
    assert_equal @pending.invitee_email, session[:pending_invitee_email]
  end

  test "show: 비로그인 + 만료 코드 → root + alert" do
    get invite_link_path(code: @expired.code)
    assert_redirected_to root_path
    assert_match(/유효하지 않/, flash[:alert])
  end

  test "show: 로그인 + 활성 → 안내만" do
    sign_in_as(@user)
    get invite_link_path(code: @pending.code)
    assert_redirected_to root_path
    assert @pending.reload.pending?
  end

  # --- create / destroy ---

  test "create: 7일 이내 발급 이력 있으면 거절" do
    sign_in_as(@user)
    assert_no_difference "Invitation.count" do
      post invitations_path, params: { invitation: { invitee_local_part: "x" } }
    end
    assert_redirected_to invitations_path
    assert_match(/무료 초대/, flash[:alert])
  end

  # --- 추가 발급권 (Phase F-2-b) ---

  test "create: 7일 이내 + pay_extra + 잔액 충분 → 즉시 발급 + 크레딧 차감" do
    cost = Rails.application.config.x.blackticket.invitation_extra_cost
    @user.credit_transactions.create!(amount: cost * 2, kind: :admin_grant, memo: "seed")
    sign_in_as(@user)
    before = @user.reload.ticket_credits

    assert_difference "Invitation.count", 1 do
      post invitations_path, params: { invitation: { invitee_local_part: "extra", pay_extra: "1" } }
    end
    inv = @user.sent_invitations.order(:created_at).last
    assert inv.paid_extra?
    assert_equal before - cost, @user.reload.ticket_credits
  end

  test "create: 7일 이내 + pay_extra + 잔액 부족 → 거절" do
    sign_in_as(@user)
    assert_no_difference "Invitation.count" do
      post invitations_path, params: { invitation: { invitee_local_part: "extra", pay_extra: "1" } }
    end
    assert_match(/크레딧이 부족/, flash[:alert])
  end

  test "InvitationExpireJob: paid_extra가 expired 시 50% 환급" do
    cost = Rails.application.config.x.blackticket.invitation_extra_cost
    refund = (cost * 0.5).to_i
    inv = @user.sent_invitations.create!(
      invitee_email: "expire-paid@gmail.com", paid_extra: true, expires_at: 1.hour.ago
    )
    inv.update_columns(status: Invitation.statuses[:pending])
    assert_difference -> { @user.reload.ticket_credits }, refund do
      InvitationExpireJob.new.perform
    end
    assert inv.reload.expired?
    assert @user.credit_transactions.exists?(kind: :refund, memo: "invitation_extra_refund")
  end

  test "InvitationExpireJob: 무료 발급은 환급 없음" do
    inv = @user.sent_invitations.create!(
      invitee_email: "expire-free@gmail.com", paid_extra: false, expires_at: 1.hour.ago
    )
    inv.update_columns(status: Invitation.statuses[:pending])
    assert_no_difference -> { @user.reload.ticket_credits } do
      InvitationExpireJob.new.perform
    end
  end

  test "create: 7일 초과 사용자는 발급 성공 + 메일 잡 enqueue (추천서 없음)" do
    sign_in_as(users(:two))
    assert_difference "Invitation.count", 1 do
      assert_enqueued_jobs 1, only: InvitationMailJob do
        post invitations_path, params: {
          invitation: { invitee_local_part: "new-friend" }
        }
      end
    end
    inv = users(:two).sent_invitations.order(:created_at).last
    assert_equal "new-friend@gmail.com", inv.invitee_email
    assert_not inv.recommendation_written?
    assert_not inv.boosted?
    assert_redirected_to invitations_path
  end

  test "create: invitee_local_part 누락 시 거절" do
    sign_in_as(users(:two))
    assert_no_difference "Invitation.count" do
      post invitations_path, params: { invitation: {} }
    end
    assert_redirected_to invitations_path
  end

  test "create: 이미 가입된 이메일은 거절" do
    sign_in_as(users(:two))
    local = @user.email_address.split("@").first # @user는 one@gmail.com
    assert_no_difference "Invitation.count" do
      post invitations_path, params: { invitation: { invitee_local_part: local } }
    end
  end

  # --- edit / update (추천서 사후 작성) ---

  def fresh_invitation_for(inviter, accepted_by: nil)
    inv = inviter.sent_invitations.create!(invitee_email: "fresh-#{SecureRandom.hex(4)}@gmail.com")
    inv.update!(status: :accepted, accepted_by: accepted_by) if accepted_by
    inv
  end

  test "edit: 추천서 미작성이면 폼 렌더" do
    sign_in_as(@user)
    inv = fresh_invitation_for(@user)
    get edit_invitation_path(inv)
    assert_response :success
  end

  test "edit: 이미 작성된 추천서면 거절" do
    sign_in_as(@user)
    get edit_invitation_path(@pending) # fixture에 이미 추천서 있음
    assert_redirected_to invitations_path
    assert_match(/이미 작성된 추천서/, flash[:alert])
  end

  test "update: 추천서 저장 + 가입한 피초대자에게 알림 발송" do
    sign_in_as(@user)
    inv = fresh_invitation_for(@user, accepted_by: @inactive)

    assert_difference "Notification.count", 1 do
      patch invitation_path(inv), params: {
        invitation: { recommendation_comment: "처음 작성하는 추천서입니다." }
      }
    end
    inv.reload
    assert_equal "처음 작성하는 추천서입니다.", inv.recommendation_comment
    notif = Notification.order(:created_at).last
    assert_equal "recommendation_written", notif.action
    assert_equal @inactive, notif.recipient
  end

  test "update: boosted 옵션 시 크레딧 차감 + boosted=true" do
    user = users(:two)
    user.credit_transactions.create!(amount: 100, kind: :admin_grant, memo: "seed")
    sign_in_as(user)
    inv = fresh_invitation_for(user)
    cost = Rails.application.config.x.blackticket.boosted_invitation_cost
    before = user.reload.ticket_credits

    patch invitation_path(inv), params: {
      invitation: { recommendation_comment: "강력 추천하는 동료입니다.", boosted: "1" }
    }
    inv.reload
    assert inv.boosted?
    assert_equal before - cost, user.reload.ticket_credits
  end

  test "update: boosted인데 크레딧 부족 시 거절" do
    user = users(:two)
    sign_in_as(user)
    inv = fresh_invitation_for(user)
    patch invitation_path(inv), params: {
      invitation: { recommendation_comment: "강력 추천 시도.", boosted: "1" }
    }
    assert_redirected_to edit_invitation_path(inv)
    assert_match(/크레딧/, flash[:alert])
    assert_not inv.reload.recommendation_written?
  end

  test "update: 이미 작성된 추천서는 거절" do
    sign_in_as(@user)
    patch invitation_path(@pending), params: {
      invitation: { recommendation_comment: "사후 수정 시도하는 추천서" }
    }
    assert_redirected_to invitations_path
    assert_match(/이미 작성된 추천서/, flash[:alert])
  end

  # --- request_recommendation ---

  test "request_recommendation: 추천서 누락 시 초대자에게 알림 발송" do
    # accepted_one — inviter: one, accepted_by: two
    invitations(:accepted_one).update_columns(recommendation_comment: nil)
    sign_in_as(users(:two))

    assert_difference "Notification.count", 1 do
      post request_recommendation_invitations_path
    end
    assert_redirected_to matching_path
    notif = Notification.order(:created_at).last
    assert_equal "recommendation_requested", notif.action
    assert_equal @user, notif.recipient
    assert_equal users(:two), notif.actor
  end

  test "request_recommendation: 이미 작성된 추천서면 알림 없이 안내" do
    sign_in_as(users(:two))
    assert_no_difference "Notification.count" do
      post request_recommendation_invitations_path
    end
    assert_redirected_to matching_path
  end

  test "destroy: 본인 pending 초대 취소" do
    sign_in_as(@user)
    delete invitation_path(@pending)
    assert_redirected_to invitations_path
    assert @pending.reload.cancelled?
  end

  test "destroy: 남의 초대는 못 건드림" do
    sign_in_as(users(:two))
    delete invitation_path(@pending)
    assert_response :not_found
    assert @pending.reload.pending?
  end

  test "resend: pending+미만료 초대 재발송" do
    sign_in_as(@user)
    assert_enqueued_jobs 1, only: InvitationMailJob do
      post resend_invitation_path(@pending)
    end
    assert_redirected_to invitations_path
  end

  test "resend: 만료된 초대는 재발송 거절" do
    sign_in_as(@user)
    assert_no_enqueued_jobs only: InvitationMailJob do
      post resend_invitation_path(@expired)
    end
    assert_match(/재발송할 수 없/, flash[:alert])
  end

  # --- 비활성 사용자: 어떤 페이지든 접근 시 자동 로그아웃 ---

  test "비활성 사용자: 프로필 접근 시 자동 로그아웃 + 로그인 페이지로" do
    sign_in_as(@inactive)
    get profile_path(@inactive)
    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "비활성 사용자: 명시적 로그아웃도 동일하게 정리" do
    sign_in_as(@inactive)
    delete session_path
    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "index: 초대 트리 렌더 (본인 + invitees 노출)" do
    @inactive.update!(invited_by: @user, invitation_accepted_at: Time.current, seed: false)
    sign_in_as(@user)
    get invitations_path
    assert_response :success
    assert_match(/초대 트리/, response.body)
    assert_match(@inactive.nickname, response.body)
  end
end
