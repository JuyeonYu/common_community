class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend

  allow_browser versions: :modern

  stale_when_importmap_changes

  before_action :set_native_variant
  before_action :ensure_nickname

  helper_method :turbo_native_app?, :admin_section?

  private
    def turbo_native_app?
      request.user_agent.to_s.match?(/Turbo Native (iOS|Android)/)
    end

    # /admin/* 영역 여부 — layout에서 사이드바 노출 분기.
    def admin_section?
      self.class.module_parent_name == "Admin"
    end

    def set_native_variant
      request.variant = :native if turbo_native_app?
    end

    # 닉네임 미설정 사용자는 프로필 편집으로 강제. 사용자 노출은 모두 닉네임 기준이므로 nil이면 화면이 비어버린다.
    def ensure_nickname
      return unless Current.user
      return if Current.user.nickname.present?
      return if controller_path.start_with?("profiles", "sessions", "rails/")
      return if request.path == new_session_path || request.path == session_path
      redirect_to edit_profile_path(Current.user), alert: "닉네임을 먼저 설정해주세요."
    end
end
