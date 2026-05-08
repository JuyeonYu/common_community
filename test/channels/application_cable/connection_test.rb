require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  setup { @user = users(:one) }

  test "유효한 세션 쿠키로 연결 성공" do
    session = @user.sessions.create!
    cookies.signed[:session_id] = session.id

    connect
    assert_equal @user, connection.current_user
  end

  test "쿠키 없으면 연결 거부" do
    assert_reject_connection { connect }
  end
end
