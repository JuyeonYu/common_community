require "test_helper"

class Admin::ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user = users(:one)
    @report = reports(:pending_post_report)
  end

  test "index: 비로그인 차단" do
    get admin_reports_path
    assert_redirected_to new_session_path
  end

  test "index: 일반 사용자 차단" do
    sign_in_as(@user)
    get admin_reports_path
    assert_redirected_to root_path
    assert_match(/권한/, flash[:alert])
  end

  test "index: admin 접근 가능" do
    sign_in_as(@admin)
    get admin_reports_path
    assert_response :success
    assert_match(/신고 관리/, response.body)
  end

  test "index: status 필터" do
    sign_in_as(@admin)
    get admin_reports_path(status: "pending")
    assert_response :success
  end

  test "update hide: 콘텐츠 숨김 + 보류 신고들 처리됨" do
    sign_in_as(@admin)
    target = @report.reportable

    patch admin_report_path(@report, decision: "hide")

    assert_redirected_to admin_reports_path
    assert target.reload.hidden?
    assert @report.reload.resolved?
    assert_equal @admin.id, @report.resolved_by_id
  end

  test "update dismiss: 신고 무시" do
    sign_in_as(@admin)
    target = @report.reportable

    patch admin_report_path(@report, decision: "dismiss")

    assert_redirected_to admin_reports_path
    assert @report.reload.dismissed?
    assert_not target.reload.hidden?
  end

  test "update restore: 콘텐츠 복원" do
    sign_in_as(@admin)
    resolved = reports(:resolved_report)

    patch admin_report_path(resolved, decision: "restore")

    assert_redirected_to admin_reports_path
    assert_not resolved.reportable.reload.hidden?
  end
end
