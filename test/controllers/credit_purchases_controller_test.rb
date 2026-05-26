require "test_helper"

class CreditPurchasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    Setting.set("bank_name", "신한은행")
    Setting.set("bank_account_number", "110-123-456789")
    Setting.set("bank_account_holder", "유주연")
  end

  test "new: 비로그인 차단" do
    get new_credit_purchase_path
    assert_redirected_to new_session_path
  end

  test "new: 로그인 사용자 → 폼 + 계좌 정보 노출" do
    sign_in_as(@user)
    get new_credit_purchase_path
    assert_response :success
    assert_match(/크레딧 충전/, response.body)
    assert_match(/신한은행/, response.body)
    assert_match(/110-123-456789/, response.body)
  end

  test "create: 정상 → CreditPurchase pending + 메일 잡 enqueue" do
    sign_in_as(@user)
    assert_difference "CreditPurchase.count", 1 do
      assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
        post credit_purchases_path, params: {
          credit_purchase: { package_key: "regular", declared_amount: 9900, declared_name: "유주연" }
        }
      end
    end
    p = CreditPurchase.last
    assert_equal @user, p.user
    assert p.pending?
    assert_redirected_to history_profile_path(@user)
  end

  test "create: 검증 실패 시 new 재렌더 (메일 안 보냄)" do
    sign_in_as(@user)
    assert_no_difference "CreditPurchase.count" do
      assert_no_enqueued_emails do
        post credit_purchases_path, params: {
          credit_purchase: { package_key: "regular", declared_amount: 0, declared_name: "" }
        }
      end
    end
    assert_response :unprocessable_entity
  end
end
