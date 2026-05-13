class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend

  allow_browser versions: :modern

  stale_when_importmap_changes

  before_action :set_native_variant

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
end
