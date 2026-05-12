require "test_helper"

class ConnectRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @male = users(:one).tap { |u|
      u.update!(gender: :male, nickname: "남자1", birth_date: 30.years.ago.to_date,
                residence_area: :seoul, job_title: "개발", smoking: :non_smoker,
                hobby: "러닝", bio: "안녕")
      u.avatar.attach(io: StringIO.new("a"), filename: "a.png", content_type: "image/png")
      u.enable_matching!
    }
    @female = users(:two).tap { |u|
      u.update!(gender: :female, nickname: "여자2", birth_date: 28.years.ago.to_date,
                residence_area: :seoul, job_title: "기획", smoking: :non_smoker,
                hobby: "사진", bio: "안녕")
      u.avatar.attach(io: StringIO.new("b"), filename: "b.png", content_type: "image/png")
      u.enable_matching!
    }
  end

  test "create: 매칭 비활성 사용자는 거절" do
    @male.disable_matching!
    sign_in_as(@male)
    assert_no_difference "ConnectRequest.count" do
      post connect_requests_path, params: { target_id: @female.id }
    end
  end

  test "create: 정상 요청 송신" do
    sign_in_as(@male)
    assert_difference "ConnectRequest.count", 1 do
      post connect_requests_path, params: { target_id: @female.id }
    end
    assert_redirected_to matching_path
  end

  test "create: 같은 기수 두 번째 시도 거절" do
    ConnectRequest.create!(requester: @male, target: @female)
    sign_in_as(@male)
    assert_no_difference "ConnectRequest.count" do
      post connect_requests_path, params: { target_id: @female.id }
    end
  end

  test "accept: 수신자만 수락 가능, RedConnect 생성" do
    req = ConnectRequest.create!(requester: @male, target: @female)
    sign_in_as(@female)
    assert_difference "RedConnect.count", 1 do
      post accept_connect_request_path(req)
    end
    assert req.reload.accepted?
  end

  test "accept: 본인이 보낸 요청에 대해서는 수락 불가" do
    req = ConnectRequest.create!(requester: @male, target: @female)
    sign_in_as(@male)
    post accept_connect_request_path(req)
    assert_response :not_found
    assert req.reload.pending?
  end

  test "reject: 수신자가 거절" do
    req = ConnectRequest.create!(requester: @male, target: @female)
    sign_in_as(@female)
    post reject_connect_request_path(req)
    assert req.reload.rejected?
  end

  test "destroy: 요청자가 본인 pending 취소" do
    req = ConnectRequest.create!(requester: @male, target: @female)
    sign_in_as(@male)
    delete connect_request_path(req)
    assert req.reload.cancelled?
  end

  test "휴식 토글 시 pending 요청 자동 취소" do
    req = ConnectRequest.create!(requester: @male, target: @female)
    @male.disable_matching!
    assert req.reload.cancelled?
  end
end
