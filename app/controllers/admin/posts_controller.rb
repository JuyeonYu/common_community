class Admin::PostsController < Admin::BaseController
  before_action :set_post, only: %i[ destroy hide unhide ]

  def index
    scope = Post.includes(:user, :tags).order(created_at: :desc)
    scope = scope.joins(:user).where("users.email_address ILIKE ? OR posts.title ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
    @pagy, @posts = pagy(scope, limit: 30)
  end

  def destroy
    @post.destroy
    redirect_to admin_posts_path, notice: "게시물을 삭제했습니다."
  end

  def hide
    @post.update!(status: :hidden)
    redirect_to admin_posts_path, notice: "숨김 처리했습니다."
  end

  def unhide
    @post.update!(status: :published)
    redirect_to admin_posts_path, notice: "공개로 복귀했습니다."
  end

  private
    def set_post
      @post = Post.find(params[:id])
    end
end
