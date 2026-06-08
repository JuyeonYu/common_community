class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create_oauth failure ]

  def new
  end

  # Google OAuth 콜백.
  # 기존 사용자: 그대로 로그인.
  # 신규 가입자: ① SeedEmail 화이트리스트 ② 세션 invitation_code + 이메일 일치 — 둘 중 하나여야 가입 가능.
  # 그 외 신규는 거절(가입 자체 X).
  def create_oauth
    auth  = request.env["omniauth.auth"]
    email = auth.info.email.to_s.downcase

    if User.exists?(google_uid: auth.uid)
      user = User.from_google_oauth(auth)
      start_new_session_for user
      redirect_to after_authentication_url and return
    end

    # 신규 가입자: 가입 권한 확인
    pending_code  = session.delete(:pending_invitation_code)
    pending_email = session.delete(:pending_invitee_email)
    invitation    = pending_code.present? ? Invitation.usable.find_by(code: pending_code) : nil
    seed_allowed  = SeedEmail.whitelisted?(email)
    invite_match  = invitation.present? && invitation.matches_email?(email)

    unless seed_allowed || invite_match
      reason = if invitation.present?
                 "초대받은 이메일(#{invitation.invitee_email})과 Google 계정 이메일이 일치하지 않습니다."
      else
                 "초대를 받은 이메일로만 가입할 수 있습니다."
      end
      redirect_to new_session_path, alert: reason and return
    end

    user = User.from_google_oauth(auth)
    invitation.redeem!(user) if invite_match && !user.active?

    start_new_session_for user
    redirect_to after_authentication_url
  rescue ActiveRecord::RecordInvalid, Invitation::EmailMismatch => e
    redirect_to new_session_path, alert: "가입 처리 중 오류: #{e.message}"
  end

  def failure
    redirect_to new_session_path, alert: "Google 로그인이 취소되었거나 실패했습니다."
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
