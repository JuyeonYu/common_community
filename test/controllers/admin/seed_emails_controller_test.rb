require "test_helper"

class Admin::SeedEmailsControllerTest < ActionDispatch::IntegrationTest
  test "index: 비admin 차단" do
    sign_in_as(users(:one))
    get admin_seed_emails_path
    assert_redirected_to root_path
  end

  test "index: admin 접근" do
    sign_in_as(users(:admin))
    get admin_seed_emails_path
    assert_response :success
    assert_match(/founder@example\.com/, response.body)
  end

  test "create: admin 추가" do
    sign_in_as(users(:admin))
    assert_difference "SeedEmail.count", 1 do
      post admin_seed_emails_path, params: { seed_email: { email: "new-founder@example.com" } }
    end
    assert_redirected_to admin_seed_emails_path
  end

  test "create: 중복 이메일 → 422" do
    sign_in_as(users(:admin))
    assert_no_difference "SeedEmail.count" do
      post admin_seed_emails_path, params: { seed_email: { email: seed_emails(:founder).email } }
    end
    assert_response :unprocessable_entity
  end

  test "destroy: admin 삭제" do
    sign_in_as(users(:admin))
    assert_difference "SeedEmail.count", -1 do
      delete admin_seed_email_path(seed_emails(:founder))
    end
  end
end
