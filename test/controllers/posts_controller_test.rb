require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other = users(:two)
    @post = posts(:welcome)
  end

  test "index: 비로그인 차단" do
    get posts_path
    assert_redirected_to new_session_path
  end

  test "index: 로그인 사용자 조회 가능" do
    sign_in_as(@user)
    get posts_path
    assert_response :success
    assert_match(/환영합니다/, response.body)
  end

  test "index: hidden 글은 노출 안 됨" do
    sign_in_as(@user)
    get posts_path
    assert_no_match(/가려진 글/, response.body)
  end

  test "index: 태그 필터" do
    sign_in_as(@user)
    get posts_path, params: { tag: "rails" }
    assert_response :success
    assert_match(/환영합니다/, response.body)
    assert_no_match(/두 번째 글/, response.body)
  end

  test "show: 조회수 증가" do
    sign_in_as(@user)
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
        post: { title: "새 글", body: "<p>내용</p>", tag_names: "rails, 신규태그" }
      }
    end
    created = Post.order(:created_at).last
    assert_redirected_to created
    assert_equal [ "rails", "신규태그" ].sort, created.tags.map(&:name).sort
  end

  test "create: title 누락 시 422" do
    sign_in_as(@user)
    assert_no_difference "Post.count" do
      post posts_path, params: { post: { title: "", body: "<p>x</p>" } }
    end
    assert_response :unprocessable_entity
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
