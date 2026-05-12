class MatchingController < ApplicationController
  # 매칭 활성화 토글 + 진입 화면.
  #   GET   /matching         — 활성: 매칭 풀(Phase D-2) / 비활성: 조건 체크리스트
  #   POST  /matching/enable  — 활성화
  #   DELETE /matching        — 휴식
  def show
    @missing_fields = Current.user.matching_missing_fields
    @can_activate   = @missing_fields.empty?
  end

  def enable
    unless Current.user.matching_profile_complete?
      redirect_to matching_path, alert: "프로필 필수 항목을 먼저 채워주세요." and return
    end
    Current.user.enable_matching!
    redirect_to matching_path, notice: "이성 매칭이 활성화되었습니다."
  end

  def destroy
    Current.user.disable_matching!
    redirect_to matching_path, notice: "이성 매칭을 일시 중지했습니다."
  end
end
