class LandingController < ApplicationController
  # Phase A 자리표시자: 비로그인은 잠금 화면, 로그인 사용자는 곧 들어올 메인(현재는 프로필로 이동).
  allow_unauthenticated_access only: :index

  def index
    redirect_to profile_path(Current.user) if Current.user
    # 비로그인은 뷰 렌더(잠금 화면)
  end
end
