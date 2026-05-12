require "test_helper"

class CreditTransactionTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "apply_to_user: 양수 충전" do
    before = @user.ticket_credits
    @user.credit_transactions.create!(amount: 5, kind: :admin_grant, memo: "test")
    assert_equal before + 5, @user.reload.ticket_credits
  end

  test "apply_to_user: 음수 차감" do
    @user.credit_transactions.create!(amount: 50, kind: :admin_grant, memo: "seed")
    @user.reload

    before = @user.ticket_credits
    @user.credit_transactions.create!(amount: -10, kind: :admin_revoke, memo: "test")
    assert_equal before - 10, @user.reload.ticket_credits
  end

  test "잔액이 음수가 되면 검증 실패" do
    assert_raises ActiveRecord::RecordInvalid do
      @user.credit_transactions.create!(amount: -1000, kind: :admin_revoke, memo: "over")
    end
  end
end
