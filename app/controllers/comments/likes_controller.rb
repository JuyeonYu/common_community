class Comments::LikesController < ApplicationController
  before_action :set_comment

  def create
    Current.user.likes.find_or_create_by!(likeable: @comment)
    render_button
  end

  def destroy
    Current.user.likes.where(likeable: @comment).destroy_all
    render_button
  end

  private
    def set_comment
      @comment = Comment.find(params[:comment_id])
    end

    def render_button
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            helpers.dom_id(@comment, :like_button),
            partial: "likes/button",
            locals: { likeable: @comment }
          )
        end
        format.html { redirect_to @comment.post }
      end
    end
end
