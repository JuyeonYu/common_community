ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

OmniAuth.config.test_mode = true

module ActiveSupport
  class TestCase
    # macOS + PostgreSQL fork 충돌로 인해 단일 worker로 실행.
    # 필요 시 PARALLEL_WORKERS 환경변수로 override 가능.
    parallelize(workers: ENV.fetch("PARALLEL_WORKERS", 1).to_i)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    teardown do
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end

    def mock_google_auth(uid: "google-uid-1", email: "test@example.com", name: "테스트", image: "https://example.com/avatar.jpg")
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: uid,
        info: { email: email, name: name, image: image }
      )
    end
  end
end
