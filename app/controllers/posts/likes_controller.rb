class Posts::LikesController < ApplicationController
  before_action :set_post

  def create
    Current.user.likes.find_or_create_by!(likeable: @post)
    render_button
  end

  def destroy
    Current.user.likes.where(likeable: @post).destroy_all
    render_button
  end

  private
    def set_post
      @post = Post.find(params[:post_id])
    end

    def render_button
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            helpers.dom_id(@post, :like_button),
            partial: "likes/button",
            locals: { likeable: @post }
          )
        end
        format.html { redirect_to @post }
      end
    end
end
