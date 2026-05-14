require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  setup do
    @author = users(:one)
    @actor  = users(:two)
    @post   = posts(:welcome)
  end

  test "action 화이트리스트" do
    n = Notification.new(recipient: @author, actor: @actor, action: "invalid", notifiable: @post)
    assert_not n.valid?
  end

  test "댓글 콜백: 글 작성자에게 알림" do
    assert_difference "Notification.count", 1 do
      @post.comments.create!(user: @actor, body: "댓글")
    end
    n = Notification.last
    assert_equal @author, n.recipient
    assert_equal @actor, n.actor
    assert_equal "commented_on_post", n.action
  end

  test "답글 콜백: 부모 댓글 작성자에게 알림" do
    parent = @post.comments.create!(user: @author, body: "부모")
    Notification.delete_all # 부모 작성으로 생긴 알림 제거 (자기 글에 자기 댓글이라 알림 0이지만 정리)

    assert_difference "Notification.count", 1 do
      @post.comments.create!(user: @actor, parent: parent, body: "답글")
    end
    n = Notification.last
    assert_equal @author, n.recipient
    assert_equal "replied_to_comment", n.action
  end

  test "자기 글에 자기 댓글은 알림 없음" do
    assert_no_difference "Notification.count" do
      @post.comments.create!(user: @author, body: "셀프 댓글")
    end
  end

  test "좋아요 콜백: 콘텐츠 작성자에게 알림" do
    fresh_post = Post.create!(user: @author, title: "임시", body: "<p>x</p>")
    assert_difference "Notification.count", 1 do
      Like.create!(user: @actor, likeable: fresh_post)
    end
    n = Notification.last
    assert_equal @author, n.recipient
    assert_equal "liked_post", n.action
  end

  test "자기 콘텐츠에 자기 좋아요는 알림 없음" do
    fresh_post = Post.create!(user: @author, title: "임시", body: "<p>x</p>")
    assert_no_difference "Notification.count" do
      Like.create!(user: @author, likeable: fresh_post)
    end
  end

  test "unread / read 스코프" do
    assert_includes Notification.unread, notifications(:unread_comment_notif)
    assert_not_includes Notification.unread, notifications(:read_like_notif)
    assert_includes Notification.read, notifications(:read_like_notif)
  end

  test "message / link_path" do
    n = notifications(:unread_comment_notif)
    assert_match(/댓글/, n.message)
    assert_equal n.notifiable.post, n.link_path
  end

  # --- 그룹화 (Phase E-2) ---

  test "deliver: 같은 group_key + 미확인이면 새 row 없이 count 증가" do
    n1 = Notification.deliver(recipient: @author, actor: @actor, action: "commented_on_post",
                              notifiable: @post, group_key: "post:#{@post.id}:comment")
    assert_difference "Notification.count", 0 do
      n2 = Notification.deliver(recipient: @author, actor: @actor, action: "commented_on_post",
                                notifiable: @post, group_key: "post:#{@post.id}:comment")
      assert_equal n1.id, n2.id
    end
    assert_equal 2, n1.reload.count
  end

  test "deliver: 같은 group_key라도 읽음 처리된 후엔 새 row" do
    n1 = Notification.deliver(recipient: @author, actor: @actor, action: "commented_on_post",
                              notifiable: @post, group_key: "post:#{@post.id}:comment")
    n1.update!(read_at: Time.current)
    assert_difference "Notification.count", 1 do
      Notification.deliver(recipient: @author, actor: @actor, action: "commented_on_post",
                           notifiable: @post, group_key: "post:#{@post.id}:comment")
    end
  end

  test "deliver: group_key 없으면 매번 새 row" do
    assert_difference "Notification.count", 2 do
      2.times do
        Notification.deliver(recipient: @author, actor: @actor, action: "commented_on_post",
                             notifiable: @post)
      end
    end
  end

  test "message: count > 1이면 접미사 표기" do
    n = Notification.deliver(recipient: @author, actor: @actor, action: "commented_on_post",
                             notifiable: @post, group_key: "post:#{@post.id}:comment")
    Notification.deliver(recipient: @author, actor: @actor, action: "commented_on_post",
                         notifiable: @post, group_key: "post:#{@post.id}:comment")
    Notification.deliver(recipient: @author, actor: @actor, action: "commented_on_post",
                         notifiable: @post, group_key: "post:#{@post.id}:comment")
    assert_match(/\(3\)/, n.reload.message)
  end

  test "deliver: 본인 자신에게는 알림 발송 X" do
    assert_no_difference "Notification.count" do
      Notification.deliver(recipient: @actor, actor: @actor, action: "commented_on_post",
                           notifiable: @post, group_key: "post:#{@post.id}:comment")
    end
  end
end
