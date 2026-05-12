class TagsController < ApplicationController
  def show
    @tag = Tag.find_by!(slug: params[:slug])
    @pagy, @posts = pagy(@tag.posts.published.includes(:user, :tags).recent, limit: 20)
  end
end
