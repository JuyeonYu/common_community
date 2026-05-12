require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user  = users(:one)
  end

  test "index: 비admin 차단" do
    sign_in_as(@user)
    get admin_users_path
    assert_redirected_to root_path
  end

  test "index: admin 접근 + 검색" do
    sign_in_as(@admin)
    get admin_users_path, params: { q: "사용자1" }
    assert_response :success
    assert_match(/사용자1/, response.body)
  end

  test "adjust_score: delta + 사유로 ScoreEvent 생성" do
    sign_in_as(@admin)
    assert_difference -> { @user.score_events.count }, 1 do
      post adjust_score_admin_user_path(@user), params: { delta: -2, memo: "테스트 페널티" }
    end
    assert_redirected_to admin_user_path(@user)
    assert_equal 8, @user.reload.ticket_score
  end

  test "adjust_score: delta 0 또는 사유 누락 거절" do
    sign_in_as(@admin)
    assert_no_difference -> { ScoreEvent.count } do
      post adjust_score_admin_user_path(@user), params: { delta: 0, memo: "x" }
    end
  end

  test "grant_credits: 양수 → admin_grant" do
    sign_in_as(@admin)
    assert_difference -> { @user.credit_transactions.count }, 1 do
      post grant_credits_admin_user_path(@user), params: { amount: 50, memo: "특별 부여" }
    end
    assert_equal "admin_grant", @user.credit_transactions.recent.first.kind
  end

  test "grant_credits: 음수 → admin_revoke" do
    @user.credit_transactions.create!(amount: 100, kind: :admin_grant, memo: "seed")
    sign_in_as(@admin)
    post grant_credits_admin_user_path(@user), params: { amount: -20, memo: "회수" }
    assert_equal "admin_revoke", @user.credit_transactions.recent.first.kind
  end

  test "suspend / unsuspend" do
    sign_in_as(@admin)
    post suspend_admin_user_path(@user)
    assert @user.reload.suspended?

    post unsuspend_admin_user_path(@user)
    assert_not @user.reload.suspended?
  end
end
