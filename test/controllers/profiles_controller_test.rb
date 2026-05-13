require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other = users(:two)
  end

  test "show: 비로그인 차단" do
    get profile_path(@user)
    assert_redirected_to new_session_path
  end

  test "show: 로그인 사용자는 조회 가능" do
    sign_in_as(@user)
    get profile_path(@user)
    assert_response :success
    assert_match(/사용자1/, response.body)
  end

  test "show: 통계 + 최근 글/댓글 미리보기 노출" do
    sign_in_as(@user)
    get profile_path(@user)
    assert_match(/작성한 글/, response.body)
    assert_match(/작성한 댓글/, response.body)
    assert_match(/최근 글/, response.body)
    assert_match(/최근 댓글/, response.body)
  end

  test "edit: 비로그인 차단" do
    get edit_profile_path(@user)
    assert_redirected_to new_session_path
  end

  test "edit: 다른 사용자 차단" do
    sign_in_as(@other)
    get edit_profile_path(@user)
    assert_redirected_to profile_path(@user)
    assert_match(/권한/, flash[:alert])
  end

  test "edit: 본인은 폼 표시" do
    sign_in_as(@user)
    get edit_profile_path(@user)
    assert_response :success
    assert_match(/프로필 수정/, response.body)
  end

  test "update: 본인 프로필 수정 성공" do
    sign_in_as(@user)
    patch profile_path(@user), params: { user: { name: "새이름", bio: "새 자기소개" } }
    assert_redirected_to profile_path(@user)
    @user.reload
    assert_equal "새이름", @user.name
    assert_equal "새 자기소개", @user.bio
  end

  test "update: 다른 사용자 차단" do
    sign_in_as(@other)
    patch profile_path(@user), params: { user: { name: "악의적변경" } }
    assert_redirected_to profile_path(@user)
    assert_not_equal "악의적변경", @user.reload.name
  end

  test "update: name 비우면 422" do
    sign_in_as(@user)
    patch profile_path(@user), params: { user: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "history: 비로그인 차단" do
    get history_profile_path(@user)
    assert_redirected_to new_session_path
  end

  test "history: 본인은 조회" do
    @user.score_events.create!(delta: 1, reason: :admin_adjust, memo: "보너스")
    sign_in_as(@user)
    get history_profile_path(@user)
    assert_response :success
    assert_match(/스코어 이력/, response.body)
    assert_match(/크레딧 이력/, response.body)
  end

  test "history: 다른 사용자 차단" do
    sign_in_as(@other)
    get history_profile_path(@user)
    assert_redirected_to profile_path(@user)
  end
end
