class CreditPurchasesController < ApplicationController
  def new
    @purchase = CreditPurchase.new(package_key: params[:package_key] || "regular")
    @packages = CreditPackages::PACKAGES
    @bank_name           = Setting.get("bank_name", default: "")
    @bank_account_number = Setting.get("bank_account_number", default: "")
    @bank_account_holder = Setting.get("bank_account_holder", default: "")
  end

  def create
    @purchase = Current.user.credit_purchases.build(purchase_params)
    if @purchase.save
      CreditPurchaseMailer.notify_admins(@purchase).deliver_later
      redirect_to history_profile_path(Current.user),
        notice: "입금 알리기 접수 완료. 입금이 확인되면 크레딧이 충전됩니다."
    else
      @packages = CreditPackages::PACKAGES
      @bank_name           = Setting.get("bank_name", default: "")
      @bank_account_number = Setting.get("bank_account_number", default: "")
      @bank_account_holder = Setting.get("bank_account_holder", default: "")
      render :new, status: :unprocessable_entity
    end
  end

  private
    def purchase_params
      params.require(:credit_purchase).permit(:package_key, :declared_amount, :declared_name)
    end
end
