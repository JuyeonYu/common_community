class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create create_oauth failure ]
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_session_path, alert: "잠시 후 다시 시도해주세요." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "이메일 또는 비밀번호를 확인해주세요."
    end
  end

  def create_oauth
    auth = request.env["omniauth.auth"]
    user = User.from_google_oauth(auth)
    start_new_session_for user
    redirect_to after_authentication_url
  rescue ActiveRecord::RecordInvalid
    redirect_to new_session_path, alert: "Google 로그인 처리 중 오류가 발생했습니다."
  end

  def failure
    redirect_to new_session_path, alert: "Google 로그인이 취소되었거나 실패했습니다."
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
