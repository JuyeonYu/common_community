class Admin::CreditPurchasesController < Admin::BaseController
  def index
    @status   = (params[:status].presence_in(CreditPurchase.statuses.keys) || "pending")
    @purchases = CreditPurchase.where(status: @status).recent.includes(:user, :processed_by)
    @counts   = CreditPurchase.group(:status).count
  end

  def update
    purchase = CreditPurchase.find(params[:id])
    case params[:resolution]
    when "fulfill"
      if purchase.fulfill!(by: Current.user, memo: params[:memo])
        redirect_to admin_credit_purchases_path, notice: "충전을 완료했습니다 (+#{purchase.total_credits} 크레딧)."
      else
        redirect_to admin_credit_purchases_path, alert: "이미 처리된 요청입니다."
      end
    when "reject"
      if purchase.reject!(by: Current.user, memo: params[:memo])
        redirect_to admin_credit_purchases_path, notice: "요청을 반려했습니다."
      else
        redirect_to admin_credit_purchases_path, alert: "이미 처리된 요청입니다."
      end
    else
      redirect_to admin_credit_purchases_path, alert: "처리 방식을 지정해주세요."
    end
  end
end
