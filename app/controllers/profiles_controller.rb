class ProfilesController < ApplicationController
  allow_unauthenticated_access only: %i[ show posts comments ]
  before_action :set_user
  before_action :require_self, only: %i[ edit update ]

  def show
    @recent_posts    = @user.posts.published.includes(:tags).recent.limit(5)
    @recent_comments = @user.comments.published.includes(:post).recent.limit(5)
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

  def posts
    @pagy, @posts = pagy(@user.posts.published.includes(:user, :tags).recent, limit: 20)
  end

  def comments
    @pagy, @comments = pagy(@user.comments.published.includes(:post, :user).recent, limit: 30)
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
      params.expect(user: [ :name, :bio, :avatar ])
    end
end
