require "test_helper"

class Admin::BoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user = users(:one)
    @free = boards(:free)
    @qa = boards(:qa)
  end

  test "index: 비admin 차단" do
    sign_in_as(@user)
    get admin_boards_path
    assert_redirected_to root_path
  end

  test "index: admin 접근" do
    sign_in_as(@admin)
    get admin_boards_path
    assert_response :success
    assert_match(/자유/, response.body)
  end

  test "create: 새 게시판" do
    sign_in_as(@admin)
    assert_difference "Board.count", 1 do
      post admin_boards_path, params: {
        board: { name: "테스트게시판", slug: "test-board", position: 5,
                 write_permission: "everyone", allowed_prefixes_text: "공지, 일반" }
      }
    end
    created = Board.find_by(slug: "test-board")
    assert_equal [ "공지", "일반" ], created.allowed_prefixes
  end

  test "destroy: 글 없으면 즉시 삭제" do
    sign_in_as(@admin)
    empty = Board.create!(name: "비어있는게시판", slug: "empty")
    assert_difference "Board.count", -1 do
      delete admin_board_path(empty)
    end
  end

  test "destroy: 글 있고 옵션 없으면 422 + 옵션 화면" do
    sign_in_as(@admin)
    delete admin_board_path(@free)
    assert_response :unprocessable_entity
    assert_match(/옵션/, response.body)
    assert Board.exists?(@free.id)
  end

  test "destroy: move_to로 글 이동 후 삭제" do
    sign_in_as(@admin)
    posts_count = @free.posts.count
    assert posts_count.positive?

    assert_difference "Board.count", -1 do
      delete admin_board_path(@free, move_to: @qa.slug)
    end
    assert_equal posts_count, @qa.reload.posts.count
  end

  test "destroy: delete_posts로 글까지 삭제" do
    sign_in_as(@admin)
    posts_count = @free.posts.count
    assert posts_count.positive?

    assert_difference -> { Board.count }, -1 do
      assert_difference -> { Post.count }, -posts_count do
        delete admin_board_path(@free, delete_posts: "true")
      end
    end
  end
end
