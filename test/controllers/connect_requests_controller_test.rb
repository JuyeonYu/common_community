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

  # --- 성사 후 차단 + 재요청 (Phase E-5) ---

  def fresh_female(local, nick)
    u = User.create!(
      email_address: "#{local}@gmail.com", name: local, nickname: nick,
      gender: :female, birth_date: 27.years.ago.to_date,
      residence_area: :seoul, job_title: "디자인", smoking: :non_smoker,
      hobby: "독서", bio: "안녕", seed: true,
      invitation_accepted_at: Time.current
    )
    u.avatar.attach(io: StringIO.new("x"), filename: "x.png", content_type: "image/png")
    u.enable_matching!
    u
  end

  test "create: 본 기수에 성사된 커넥트 있으면 새 요청 차단" do
    ConnectRequest.create!(requester: @male, target: @female).accept!
    other_female = fresh_female("ofemale", "여자3")
    sign_in_as(@male)
    assert_no_difference "ConnectRequest.count" do
      post connect_requests_path, params: { target_id: other_female.id }
    end
    assert_match(/이미 성사된 커넥트/, flash[:alert])
  end

  test "create: 거절된 상대에게 같은 기수 재요청 불가" do
    ConnectRequest.create!(requester: @male, target: @female).reject!
    sign_in_as(@male)
    assert_no_difference "ConnectRequest.count" do
      post connect_requests_path, params: { target_id: @female.id }
    end
    assert_match(/거절된 상대/, flash[:alert])
  end

  test "create: 거절 후 다른 후보에 1크레딧 차감 + 1회 재요청 성공" do
    ConnectRequest.create!(requester: @male, target: @female).reject!
    @male.credit_transactions.create!(amount: 10, kind: :admin_grant, memo: "seed")
    other_female = fresh_female("ofemale", "여자3")
    sign_in_as(@male)
    before = @male.reload.ticket_credits

    assert_difference "ConnectRequest.count", 1 do
      post connect_requests_path, params: { target_id: other_female.id }
    end
    cost = Rails.application.config.x.blackticket.connect_retry_cost
    assert_equal before - cost, @male.reload.ticket_credits
  end

  test "create: 재요청 두 번째는 차단(원샷 소진)" do
    ConnectRequest.create!(requester: @male, target: @female).reject!
    @male.credit_transactions.create!(amount: 10, kind: :admin_grant, memo: "seed")
    other_female = fresh_female("ofemale", "여자3")
    third = fresh_female("third", "여자4")
    sign_in_as(@male)
    post connect_requests_path, params: { target_id: other_female.id }
    assert_no_difference "ConnectRequest.count" do
      post connect_requests_path, params: { target_id: third.id }
    end
    assert_match(/재요청 기회/, flash[:alert])
  end

  test "create: 재요청 크레딧 부족이면 거절" do
    ConnectRequest.create!(requester: @male, target: @female).reject!
    other_female = fresh_female("ofemale", "여자3")
    sign_in_as(@male)
    assert_no_difference "ConnectRequest.count" do
      post connect_requests_path, params: { target_id: other_female.id }
    end
    assert_match(/크레딧이 부족/, flash[:alert])
  end

  test "accept: 본 기수 RedConnect 있으면 다른 요청 수락 불가" do
    ConnectRequest.create!(requester: @male, target: @female).accept!
    other_male = User.create!(
      email_address: "om@gmail.com", name: "om", nickname: "남자2",
      gender: :male, birth_date: 30.years.ago.to_date,
      residence_area: :seoul, job_title: "개발", smoking: :non_smoker,
      hobby: "러닝", bio: "안녕", seed: true,
      invitation_accepted_at: Time.current
    )
    other_male.avatar.attach(io: StringIO.new("d"), filename: "d.png", content_type: "image/png")
    other_male.enable_matching!
    incoming = ConnectRequest.create!(requester: other_male, target: @female)
    sign_in_as(@female)
    post accept_connect_request_path(incoming)
    assert incoming.reload.pending?
    assert_match(/이미 성사된 커넥트/, flash[:alert])
  end
end
