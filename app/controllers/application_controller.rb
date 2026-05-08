class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend

  allow_browser versions: :modern

  stale_when_importmap_changes

  before_action :set_native_variant

  helper_method :turbo_native_app?

  private
    def turbo_native_app?
      request.user_agent.to_s.match?(/Turbo Native (iOS|Android)/)
    end

    def set_native_variant
      request.variant = :native if turbo_native_app?
    end
end
