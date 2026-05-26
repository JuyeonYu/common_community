require "test_helper"

class CreditPurchaseTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "유효한 입금 알리기 생성" do
    p = @user.credit_purchases.build(package_key: "starter", declared_amount: 4900, declared_name: "유주연")
    assert p.valid?
  end

  test "package_key 화이트리스트 검증" do
    p = @user.credit_purchases.build(package_key: "invalid", declared_amount: 4900, declared_name: "유주연")
    assert_not p.valid?
    assert_includes p.errors.attribute_names, :package_key
  end

  test "declared_amount 양수 강제" do
    p = @user.credit_purchases.build(package_key: "starter", declared_amount: 0, declared_name: "유주연")
    assert_not p.valid?
  end

  test "declared_name 최소 길이" do
    p = @user.credit_purchases.build(package_key: "starter", declared_amount: 4900, declared_name: "a")
    assert_not p.valid?
  end

  test "fulfill!: pending → fulfilled + 사용자 크레딧 +total_credits" do
    p = @user.credit_purchases.create!(package_key: "regular", declared_amount: 9900, declared_name: "유주연")
    admin = users(:admin)
    before = @user.reload.ticket_credits
    expected = CreditPackages.total_credits_for("regular")

    assert p.fulfill!(by: admin, memo: "확인됨")
    assert p.reload.fulfilled?
    assert_equal admin, p.processed_by
    assert_equal before + expected, @user.reload.ticket_credits
    assert @user.credit_transactions.exists?(kind: :purchase, related_type: "CreditPurchase", related_id: p.id)
  end

  test "fulfill!: pending 아니면 거절" do
    p = @user.credit_purchases.create!(package_key: "starter", declared_amount: 4900, declared_name: "유주연")
    p.update!(status: :fulfilled)
    assert_not p.fulfill!(by: users(:admin))
  end

  test "reject!: pending → rejected" do
    p = @user.credit_purchases.create!(package_key: "starter", declared_amount: 4900, declared_name: "유주연")
    assert p.reject!(by: users(:admin), memo: "입금 미확인")
    assert p.reload.rejected?
  end
end
