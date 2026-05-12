module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
    before_action :require_authentication
    before_action :require_active_user
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      skip_before_action :require_active_user, **options
    end

    # 잠금 상태(가입은 했으나 초대 코드 미적용)에서도 허용할 액션. 예: 코드 입력 화면, 로그아웃.
    def allow_inactive_access(**options)
      skip_before_action :require_active_user, **options
    end
  end

  private
    def authenticated?
      Current.session.present?
    end

    def require_authentication
      Current.session.present? || request_authentication
    end

    # 비활성 사용자는 적절한 곳으로 강제 이동.
    #   정지(suspended_until 미래) → 정지 안내 페이지(현재는 로그아웃 + alert)
    #   가입 후 초대 코드 미적용     → 코드 입력 화면
    def require_active_user
      return unless Current.user
      if Current.user.suspended?
        until_at = I18n.l(Current.user.suspended_until, format: :short)
        terminate_session
        redirect_to new_session_path, alert: "정지된 계정입니다. 해제 시점: #{until_at}"
      elsif !Current.user.active?
        redirect_to redeem_invitations_path
      end
    end

    def require_admin
      return if Current.user&.admin?
      redirect_to root_path, alert: "권한이 없습니다."
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
