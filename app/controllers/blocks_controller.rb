class BlocksController < ApplicationController
  before_action :set_block, only: %i[ destroy ]

  def index
    @pagy, @blocks = pagy(
      Current.user.blocks_made.includes(:blocked).order(created_at: :desc),
      limit: 30
    )
  end

  def create
    blocked = User.find(params[:blocked_id])

    if blocked.id == Current.user.id
      redirect_back_or_to blocks_path, alert: "자기 자신을 차단할 수 없습니다." and return
    end

    @block = Current.user.blocks_made.find_or_initialize_by(blocked: blocked)
    @block.reason = params[:reason] if params[:reason].present?

    if @block.save
      redirect_back_or_to blocks_path, notice: "#{blocked.name}님을 차단했습니다."
    else
      redirect_back_or_to blocks_path, alert: @block.errors.full_messages.first
    end
  end

  def destroy
    @block.destroy
    redirect_to blocks_path, notice: "차단을 해제했습니다.", status: :see_other
  end

  private
    def set_block
      @block = Current.user.blocks_made.find(params[:id])
    end
end
