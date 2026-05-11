class BoardsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
    @boards = Board.ordered
  end

  def show
    @board = Board.find_by!(slug: params[:slug])
    scope = @board.posts.for_feed
    @pagy, @posts = pagy(scope.recent, limit: 20)
  end
end
