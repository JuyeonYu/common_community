require "test_helper"

class Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user  = users(:one)
  end

  test "show: 비admin은 거절" do
    sign_in_as(@user)
    get admin_settings_path
    assert_redirected_to root_path
  end

  test "show: admin은 폼 렌더" do
    sign_in_as(@admin)
    get admin_settings_path
    assert_response :success
    assert_match(/운영 설정/, response.body)
  end

  test "update: 3개 키 저장" do
    sign_in_as(@admin)
    patch admin_settings_path, params: {
      settings: {
        bank_name: "신한은행",
        bank_account_number: "110-123-456789",
        bank_account_holder: "유주연"
      }
    }
    assert_redirected_to admin_settings_path
    assert_equal "신한은행", Setting.get("bank_name")
    assert_equal "110-123-456789", Setting.get("bank_account_number")
    assert_equal "유주연", Setting.get("bank_account_holder")
  end
end
