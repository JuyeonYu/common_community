require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other = users(:two)
    @post = posts(:welcome)
  end

  test "index: 비로그인도 조회 가능" do
    get posts_path
    assert_response :success
    assert_match(/환영합니다/, response.body)
  end

  test "index: hidden 글은 노출 안 됨" do
    get posts_path
    assert_no_match(/가려진 글/, response.body)
  end

  test "index: 태그 필터" do
    get posts_path, params: { tag: "rails" }
    assert_response :success
    assert_match(/환영합니다/, response.body)
    assert_no_match(/두 번째 글/, response.body)
  end

  test "show: 조회수 증가" do
    assert_difference -> { @post.reload.views_count }, 1 do
      get post_path(@post)
    end
    assert_response :success
  end

  test "new: 비로그인은 로그인 페이지로" do
    get new_post_path
    assert_redirected_to new_session_path
  end

  test "new: 로그인 사용자는 폼 표시" do
    sign_in_as(@user)
    get new_post_path
    assert_response :success
  end

  test "create: 글 생성 + 태그 연결" do
    sign_in_as(@user)
    assert_difference "Post.count", 1 do
      post posts_path, params: {
        post: { board_id: boards(:free).id, title: "새 글", body: "<p>내용</p>", tag_names: "rails, 신규태그" }
      }
    end
    created = Post.order(:created_at).last
    assert_redirected_to created
    assert_equal [ "rails", "신규태그" ].sort, created.tags.map(&:name).sort
    assert_equal boards(:free).id, created.board_id
  end

  test "create: title 누락 시 422" do
    sign_in_as(@user)
    assert_no_difference "Post.count" do
      post posts_path, params: { post: { board_id: boards(:free).id, title: "", body: "<p>x</p>" } }
    end
    assert_response :unprocessable_entity
  end

  test "new: board 미지정이면 첫 번째 쓸 수 있는 게시판이 기본 선택됨" do
    sign_in_as(@user)
    get new_post_path
    assert_response :success
    assert_match(/게시판/, response.body)
    assert_match(/제목/, response.body)
  end

  test "new: board_slug로 기본 선택 보드 지정 가능" do
    sign_in_as(@user)
    get new_post_path(board_slug: "qa")
    assert_response :success
    # qa 게시판이 기본 선택되어 있는지 (selected="selected"와 함께 qa의 id가 있어야 함)
    qa_id = boards(:qa).id
    assert_match(/selected="selected"\s+value="#{qa_id}"|value="#{qa_id}"\s+selected/, response.body)
  end

  test "create: admin_only 게시판에 일반 사용자 차단" do
    sign_in_as(@user)
    notice = boards(:notice)
    assert_no_difference "Post.count" do
      post posts_path, params: { post: { board_id: notice.id, title: "x", body: "<p>x</p>" } }
    end
    assert_redirected_to posts_path
  end

  test "edit/update: 본인만 가능" do
    sign_in_as(@other)
    get edit_post_path(@post)
    assert_redirected_to posts_path
    assert_match(/권한/, flash[:alert])
  end

  test "update: 본인 글 수정 성공" do
    sign_in_as(@user)
    patch post_path(@post), params: { post: { title: "수정됨" } }
    assert_redirected_to @post
    assert_equal "수정됨", @post.reload.title
  end

  test "destroy: 본인 글 삭제" do
    sign_in_as(@user)
    assert_difference "Post.count", -1 do
      delete post_path(@post)
    end
    assert_redirected_to posts_path
  end

  test "destroy: 다른 사용자는 차단" do
    sign_in_as(@other)
    assert_no_difference "Post.count" do
      delete post_path(@post)
    end
    assert_redirected_to posts_path
  end

  test "destroy: admin은 다른 사람 글도 삭제 가능" do
    sign_in_as(users(:admin))
    assert_difference "Post.count", -1 do
      delete post_path(@post)
    end
    assert_redirected_to posts_path
  end

  test "index: q 검색 파라미터로 결과 노출" do
    get posts_path, params: { q: "환영" }
    assert_response :success
    assert_match(/환영합니다/, response.body)
    assert_no_match(/두 번째 글/, response.body)
  end

  test "index: q 매칭 없으면 안내 문구 표시" do
    get posts_path, params: { q: "절대없는키워드xyzzz" }
    assert_response :success
    assert_match(/검색 결과가 없습니다/, response.body)
  end

  test "for_feed: user/tags 미리 로드 (N+1 방지)" do
    posts = Post.for_feed.recent.to_a
    assert_predicate posts.size, :positive?

    assert_queries_count(0) do
      posts.each do |post|
        post.user.name
        post.tags.map(&:name)
      end
    end
  end
end
