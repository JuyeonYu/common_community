class CommentsController < ApplicationController
  before_action :set_post, only: %i[ create ]
  before_action :set_comment, only: %i[ edit update destroy ]
  before_action :require_author, only: %i[ edit update destroy ]

  def edit
  end

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @post, notice: "댓글이 등록되었습니다." }
      end
    else
      redirect_to @post, alert: @comment.errors.full_messages.first
    end
  end

  def update
    if @comment.update(update_params)
      redirect_to @comment.post, notice: "댓글이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @comment.post, notice: "댓글이 삭제되었습니다.", status: :see_other }
    end
  end

  private
    def set_post
      @post = Post.find(params[:post_id])
    end

    def set_comment
      @comment = Comment.includes(:user, :post).find(params[:id])
    end

    def require_author
      return if @comment.author?(Current.user) || Current.user&.admin?
      redirect_to @comment.post, alert: "권한이 없습니다."
    end

    def comment_params
      params.expect(comment: [ :body, :parent_id ])
    end

    def update_params
      params.expect(comment: [ :body ])
    end
end
