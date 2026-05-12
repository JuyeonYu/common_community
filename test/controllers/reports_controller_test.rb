require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @post = posts(:welcome)
    @comment = comments(:top_on_welcome)
  end

  test "new: 비로그인은 로그인 페이지로" do
    get new_report_path(reportable_type: "Post", reportable_id: @post.id)
    assert_redirected_to new_session_path
  end

  test "new: 로그인 사용자는 폼 표시" do
    sign_in_as(@user)
    get new_report_path(reportable_type: "Post", reportable_id: @post.id)
    assert_response :success
    assert_match(/신고하기/, response.body)
  end

  test "new: 잘못된 type은 거부" do
    sign_in_as(@user)
    get new_report_path(reportable_type: "User", reportable_id: 1)
    assert_response :bad_request
  end

  test "create: post 신고" do
    sign_in_as(@user)
    assert_difference "Report.count", 1 do
      post reports_path, params: {
        reportable_type: "Post", reportable_id: @post.id,
        report: { reason: "신고 사유 테스트" }
      }
    end
    assert_redirected_to @post
  end

  test "create: comment 신고" do
    sign_in_as(@user)
    assert_difference "Report.count", 1 do
      post reports_path, params: {
        reportable_type: "Comment", reportable_id: @comment.id,
        report: { reason: "신고 사유 테스트" }
      }
    end
    assert_redirected_to @comment.post
  end

  test "create: reason 누락 시 422" do
    sign_in_as(@user)
    assert_no_difference "Report.count" do
      post reports_path, params: {
        reportable_type: "Post", reportable_id: @post.id,
        report: { reason: "" }
      }
    end
    assert_response :unprocessable_entity
  end
end
