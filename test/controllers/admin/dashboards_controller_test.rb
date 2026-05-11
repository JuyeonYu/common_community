require "test_helper"

class Admin::DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "show: 비admin 차단" do
    sign_in_as(users(:one))
    get admin_dashboard_path
    assert_redirected_to root_path
  end

  test "show: admin 접근 + 통계 표시" do
    sign_in_as(users(:admin))
    get admin_dashboard_path
    assert_response :success
    assert_match(/대시보드/, response.body)
    assert_match(/전체 글/, response.body)
  end
end
