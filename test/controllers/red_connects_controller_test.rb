require "test_helper"

class RedConnectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @u1 = users(:one)
    @u2 = users(:two)
    @rc = RedConnect.create!(user_a: @u1, user_b: @u2, expires_at: 1.month.from_now)
  end

  test "show: 비참여자는 404" do
    sign_in_as(users(:admin))
    get red_connect_path(@rc)
    assert_response :not_found
  end

  test "show: 참여자 조회" do
    sign_in_as(@u1)
    get red_connect_path(@rc)
    assert_response :success
  end

  test "destroy: 참여자 해제 + 상대 알림" do
    sign_in_as(@u1)
    assert_difference "Notification.where(action: 'connect_released', recipient_id: @u2.id).count", 1 do
      delete red_connect_path(@rc)
    end
    assert @rc.reload.released?
    assert_redirected_to red_connects_path
  end

  # --- 연장권 (Phase F-2-a) ---

  test "extend_duration: active + 잔액 충분 → +1개월 + 크레딧 차감" do
    cost = Rails.application.config.x.blackticket.red_connect_extension_cost
    @u1.credit_transactions.create!(amount: cost * 2, kind: :admin_grant, memo: "seed")
    sign_in_as(@u1)
    before_credits = @u1.reload.ticket_credits
    before_expiry  = @rc.expires_at

    post extend_duration_red_connect_path(@rc)
    assert_in_delta (before_expiry + 1.month).to_i, @rc.reload.expires_at.to_i, 5
    assert_equal before_credits - cost, @u1.reload.ticket_credits
  end

  test "extend_duration: expired → active 복귀 + 만료일 갱신" do
    @rc.update_columns(status: RedConnect.statuses[:expired], expires_at: 1.day.ago)
    cost = Rails.application.config.x.blackticket.red_connect_extension_cost
    @u1.credit_transactions.create!(amount: cost * 2, kind: :admin_grant, memo: "seed")
    sign_in_as(@u1)

    post extend_duration_red_connect_path(@rc)
    assert @rc.reload.active?
    assert @rc.expires_at > Time.current
  end

  test "extend_duration: released는 거절" do
    @rc.update_columns(status: RedConnect.statuses[:released])
    cost = Rails.application.config.x.blackticket.red_connect_extension_cost
    @u1.credit_transactions.create!(amount: cost * 2, kind: :admin_grant, memo: "seed")
    sign_in_as(@u1)

    post extend_duration_red_connect_path(@rc)
    assert @rc.reload.released?
    assert_match(/해제된 커넥트/, flash[:alert])
  end

  test "extend_duration: 잔액 부족 거절" do
    sign_in_as(@u1)
    post extend_duration_red_connect_path(@rc)
    assert_match(/크레딧이 부족/, flash[:alert])
  end

  test "extend_duration: 비참여자는 404" do
    sign_in_as(users(:admin))
    post extend_duration_red_connect_path(@rc)
    assert_response :not_found
  end
end
