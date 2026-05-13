class ProfilesController < ApplicationController
  before_action :set_user
  before_action :require_self, only: %i[ edit update history ]

  def show
    @recent_posts    = @user.posts.published.includes(:tags).order(created_at: :desc).limit(5)
    @recent_comments = @user.comments.published.includes(:post).order(created_at: :desc).limit(5)
    @post_count      = @user.posts.published.count
    @comment_count   = @user.comments.published.count
  end

  # 본인 스코어/크레딧 이력. 양이 많을 수 있어 각각 페이지네이션 분리(키 score_page/credit_page).
  def history
    @pagy_score,  @score_events  = pagy(@user.score_events.recent,        limit: 30, page_param: :score_page)
    @pagy_credit, @credit_txns   = pagy(@user.credit_transactions.recent, limit: 30, page_param: :credit_page)
  end

  def posts
    @pagy, @posts = pagy(@user.posts.published.includes(:user, :tags).recent, limit: 20)
  end

  def comments
    @pagy, @comments = pagy(@user.comments.published.includes(:post, :user).recent, limit: 30)
  end

  def edit
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path(@user), notice: "프로필이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def require_self
      return if Current.user&.id == @user.id
      redirect_to profile_path(@user), alert: "권한이 없습니다."
    end

    def profile_params
      params.expect(user: [
        :name, :nickname, :bio, :avatar,
        :hobby, :residence_area, :job_title, :smoking, :birth_date, :gender,
        { notification_preferences: [ :web_push ] }
      ])
    end
end
