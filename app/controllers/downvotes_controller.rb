class DownvotesController < ApplicationController
  before_action :set_red_connect

  def create
    other = @red_connect.other_user(Current.user)
    dv = Downvote.new(
      from_user: Current.user, to_user: other,
      red_connect: @red_connect,
      kind: params[:kind], comment: params[:comment].to_s.strip
    )
    if dv.save
      redirect_to matching_path, notice: "비추천이 처리되었습니다. 커넥트가 종료됩니다."
    else
      redirect_to red_connect_path(@red_connect), alert: dv.errors.full_messages.first
    end
  end

  private
    def set_red_connect
      @red_connect = RedConnect.for_user(Current.user).find(params[:red_connect_id])
    end
end
