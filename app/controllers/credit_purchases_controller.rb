class CreditPurchasesController < ApplicationController
  def new
    @purchase = CreditPurchase.new(package_key: params[:package_key] || "regular")
    @packages = CreditPackages::PACKAGES
    @bank_name           = Setting.get("bank_name", default: "")
    @bank_account_number = Setting.get("bank_account_number", default: "")
    @bank_account_holder = Setting.get("bank_account_holder", default: "")
  end

  def create
    via = params.dig(:credit_purchase, :paid_via).to_s
    case via
    when "portone_card"
      create_portone
    else
      create_bank_transfer
    end
  end

  private
    def create_bank_transfer
      @purchase = Current.user.credit_purchases.build(bank_transfer_params)
      @purchase.paid_via = :bank_transfer
      if @purchase.save
        CreditPurchaseMailer.notify_admins(@purchase).deliver_later
        redirect_to history_profile_path(Current.user),
          notice: "입금 알리기 접수 완료. 입금이 확인되면 크레딧이 충전됩니다."
      else
        rerender_new
      end
    end

    # PortOne 카드 결제 — JS SDK가 성공 후 paymentId를 보내옴.
    # 서버에서 PortOne REST로 결제 상태/금액 검증한 뒤 자동 fulfill.
    def create_portone
      key = params.dig(:credit_purchase, :package_key).to_s
      external_id = params.dig(:credit_purchase, :external_payment_id).to_s
      if !CreditPackages::KEYS.include?(key) || external_id.blank?
        redirect_to new_credit_purchase_path, alert: "결제 요청이 유효하지 않습니다." and return
      end

      code, body = PortOne.get_payment(external_id)
      expected = CreditPackages.price_for(key)
      paid_amount = body.dig("amount", "total") || body["totalAmount"]
      status = body["status"]

      unless code == 200 && status == "PAID" && paid_amount.to_i == expected
        Rails.logger.warn "[PortOne] payment verify failed code=#{code} status=#{status} amount=#{paid_amount} expected=#{expected}"
        redirect_to new_credit_purchase_path,
          alert: "결제 검증 실패: 운영자에 문의해주세요." and return
      end

      @purchase = Current.user.credit_purchases.build(
        package_key: key,
        declared_amount: expected,
        declared_name: Current.user.nickname, # PortOne에선 이름 미수집 — 닉네임으로 채움
        paid_via: :portone_card,
        external_payment_id: external_id,
        paid_at: Time.current
      )
      if @purchase.save && @purchase.fulfill!(by: Current.user, memo: "PortOne 자동 충전")
        redirect_to history_profile_path(Current.user),
          notice: "결제가 완료되어 #{@purchase.total_credits} 크레딧이 충전되었습니다."
      else
        redirect_to new_credit_purchase_path,
          alert: "충전 처리 중 오류가 발생했습니다. 운영자에 문의해주세요."
      end
    end

    def rerender_new
      @packages = CreditPackages::PACKAGES
      @bank_name           = Setting.get("bank_name", default: "")
      @bank_account_number = Setting.get("bank_account_number", default: "")
      @bank_account_holder = Setting.get("bank_account_holder", default: "")
      render :new, status: :unprocessable_entity
    end

    def bank_transfer_params
      params.require(:credit_purchase).permit(:package_key, :declared_amount, :declared_name)
    end
end
