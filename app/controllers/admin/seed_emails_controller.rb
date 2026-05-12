class Admin::SeedEmailsController < Admin::BaseController
  def index
    @seed_emails = SeedEmail.order(created_at: :desc).limit(100)
    @seed_email  = SeedEmail.new
  end

  def create
    @seed_email = SeedEmail.new(email: params.dig(:seed_email, :email), created_by: Current.user)
    if @seed_email.save
      redirect_to admin_seed_emails_path, notice: "시드 이메일을 추가했습니다."
    else
      @seed_emails = SeedEmail.order(created_at: :desc).limit(100)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    SeedEmail.find(params[:id]).destroy
    redirect_to admin_seed_emails_path, notice: "시드 이메일을 삭제했습니다."
  end
end
