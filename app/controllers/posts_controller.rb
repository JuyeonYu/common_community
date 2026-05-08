class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_post, only: %i[ show edit update destroy ]
  before_action :require_author, only: %i[ edit update destroy ]

  def index
    scope = Post.for_feed
    scope = scope.joins(:tags).where(tags: { slug: params[:tag] }).distinct if params[:tag].present?

    if params[:q].present?
      @query = params[:q].to_s.strip
      scope = scope.search_by_text(@query)
      @pagy, @posts = pagy(scope, limit: 20)
    else
      @pagy, @posts = pagy(scope.recent, limit: 20)
    end
  end

  def show
    Post.where(id: @post.id).update_all("views_count = views_count + 1")
  end

  def new
    @post = Current.user.posts.build
  end

  def create
    @post = Current.user.posts.build(post_params)
    if @post.save
      redirect_to @post, notice: "글이 등록되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "글이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "글이 삭제되었습니다.", status: :see_other
  end

  private
    def set_post
      @post = Post.includes(:user, :tags).find(params[:id])
    end

    def require_author
      redirect_to posts_path, alert: "권한이 없습니다." unless @post.author?(Current.user) || Current.user&.admin?
    end

    def post_params
      params.expect(post: [ :title, :body, :tag_names ])
    end
end
