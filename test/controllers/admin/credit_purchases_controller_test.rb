require "test_helper"

class Admin::CreditPurchasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user  = users(:one)
    @purchase = @user.credit_purchases.create!(package_key: "regular", declared_amount: 9900, declared_name: "유주연")
  end

  test "index: 비admin 거절" do
    sign_in_as(@user)
    get admin_credit_purchases_path
    assert_redirected_to root_path
  end

  test "index: admin 페이지 렌더 + pending 목록" do
    sign_in_as(@admin)
    get admin_credit_purchases_path
    assert_response :success
    assert_match(/충전 요청/, response.body)
    assert_match(@user.nickname, response.body)
  end

  test "update fulfill: 사용자 크레딧 충전 + status fulfilled" do
    sign_in_as(@admin)
    before = @user.reload.ticket_credits
    expected = CreditPackages.total_credits_for("regular")

    patch admin_credit_purchase_path(@purchase, resolution: "fulfill")
    assert_redirected_to admin_credit_purchases_path
    assert @purchase.reload.fulfilled?
    assert_equal before + expected, @user.reload.ticket_credits
    assert_equal @admin, @purchase.processed_by
  end

  test "update reject: status rejected, 크레딧 변동 없음" do
    sign_in_as(@admin)
    before = @user.reload.ticket_credits

    patch admin_credit_purchase_path(@purchase, resolution: "reject")
    assert @purchase.reload.rejected?
    assert_equal before, @user.reload.ticket_credits
  end

  test "update fulfill: 이미 처리된 요청은 거절" do
    @purchase.update!(status: :fulfilled)
    sign_in_as(@admin)
    patch admin_credit_purchase_path(@purchase, resolution: "fulfill")
    assert_match(/이미 처리/, flash[:alert])
  end
end
