class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[ show adjust_score grant_credits suspend unsuspend ]

  def index
    scope = User.order(created_at: :desc)
    if (q = params[:q].to_s.strip).present?
      scope = scope.where("email_address ILIKE ? OR name ILIKE ? OR nickname ILIKE ?", "%#{q}%", "%#{q}%", "%#{q}%")
    end
    @users = scope.limit(50)
  end

  def show
    @score_events  = @user.score_events.recent.limit(30)
    @credit_txns   = @user.credit_transactions.recent.limit(30)
  end

  # 스코어 조정 — admin이 사유와 함께 +/-.
  def adjust_score
    delta = params[:delta].to_i
    memo  = params[:memo].to_s.strip
    if delta.zero? || memo.blank?
      redirect_to admin_user_path(@user), alert: "delta와 사유를 입력해주세요." and return
    end
    @user.score_events.create!(delta: delta, reason: :admin_adjust, memo: memo)
    redirect_to admin_user_path(@user), notice: "스코어 조정 완료."
  end

  # 크레딧 부여/차감.
  def grant_credits
    amount = params[:amount].to_i
    memo   = params[:memo].to_s.strip
    if amount.zero? || memo.blank?
      redirect_to admin_user_path(@user), alert: "amount와 사유를 입력해주세요." and return
    end
    kind = amount.positive? ? :admin_grant : :admin_revoke
    @user.credit_transactions.create!(amount: amount, kind: kind, memo: memo)
    redirect_to admin_user_path(@user), notice: "크레딧 조정 완료."
  end

  def suspend
    @user.suspend!
    redirect_to admin_user_path(@user), notice: "정지 완료 — #{l(@user.suspended_until, format: :short)} 까지"
  end

  def unsuspend
    @user.unsuspend!
    redirect_to admin_user_path(@user), notice: "정지 해제 완료."
  end

  private
    def set_user
      @user = User.find(params[:id])
    end
end
