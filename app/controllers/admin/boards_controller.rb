class Admin::BoardsController < Admin::BaseController
  before_action :set_board, only: %i[ edit update destroy ]

  def index
    @boards = Board.ordered.left_joins(:posts).group("boards.id").select("boards.*, COUNT(posts.id) AS posts_count")
  end

  def new
    @board = Board.new(position: next_position, allowed_prefixes: [])
  end

  def create
    @board = Board.new(board_params)
    if @board.save
      redirect_to admin_boards_path, notice: "게시판이 생성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @board.update(board_params)
      redirect_to admin_boards_path, notice: "게시판이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @board.posts.empty?
      @board.destroy
      redirect_to admin_boards_path, notice: "게시판이 삭제되었습니다.", status: :see_other
    else
      handle_destroy_with_posts
    end
  end

  private
    def set_board
      # Board#to_param이 slug를 반환하므로 params[:id]는 slug 값.
      @board = Board.find_by!(slug: params[:id])
    end

    def board_params
      raw = params.expect(board: [ :name, :slug, :description, :position, :write_permission, :allowed_prefixes_text ])
      raw.delete(:allowed_prefixes_text).then do |text|
        raw[:allowed_prefixes] = parse_prefixes(text)
      end
      raw
    end

    # 콤마 또는 줄바꿈으로 구분된 입력을 배열로
    def parse_prefixes(text)
      text.to_s.split(/[,\n]/).map(&:strip).reject(&:blank?).uniq
    end

    def next_position
      (Board.maximum(:position) || -1) + 1
    end

    def handle_destroy_with_posts
      if (slug = params[:move_to]).present?
        target = Board.find_by!(slug: slug)
        if target.id == @board.id
          redirect_to admin_boards_path, alert: "같은 게시판으로는 이동할 수 없습니다." and return
        end
        Post.where(board_id: @board.id).update_all(board_id: target.id)
        @board.destroy
        redirect_to admin_boards_path, notice: "글을 #{target.name}로 이동 후 게시판을 삭제했습니다.", status: :see_other
      elsif params[:delete_posts] == "true"
        @board.posts.destroy_all
        @board.destroy
        redirect_to admin_boards_path, notice: "글까지 모두 삭제했습니다.", status: :see_other
      else
        @other_boards = Board.where.not(id: @board.id).ordered
        @posts_count  = @board.posts.count
        render :destroy_with_posts, status: :unprocessable_entity
      end
    end
end
