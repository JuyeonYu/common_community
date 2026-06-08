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
  end

  private
    def authenticated?
      Current.session.present?
    end

    def require_authentication
      Current.session.present? || request_authentication
    end

    # 비활성 사용자는 즉시 로그아웃 처리.
    # 신규 가입 흐름이 가입 단계에서 활성화까지 완료시키므로(D-6),
    # 여기 도달하는 케이스는 옛 데이터 / 정지 / 어떤 edge case 잔재뿐.
    # 일관성 있게 모두 logout + alert로 처리.
    def require_active_user
      return unless Current.user
      return if Current.user.active?

      alert = if Current.user.suspended?
                until_at = I18n.l(Current.user.suspended_until, format: :short)
                "정지된 계정입니다. 해제 시점: #{until_at}"
      else
                "계정 활성화 상태가 아닙니다. 다시 초대 메일의 링크로 가입을 진행해주세요."
      end
      terminate_session
      redirect_to new_session_path, alert: alert
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
