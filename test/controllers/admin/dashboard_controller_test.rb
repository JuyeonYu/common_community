require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "비admin 차단" do
    sign_in_as(users(:one))
    get admin_root_path
    assert_redirected_to root_path
  end

  test "admin 접근" do
    sign_in_as(users(:admin))
    get admin_root_path
    assert_response :success
    assert_match(/관리 대시보드/, response.body)
  end
end
