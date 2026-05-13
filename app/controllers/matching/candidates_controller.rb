class Matching::CandidatesController < ApplicationController
  before_action :ensure_matching_active

  # 매칭 풀의 후보 1명에 대한 제한된 프로필 페이지.
  # 노출: 닉네임/나이/성별/거주지/직무/흡연/취미/bio + 아바타 + 추천서 + boosted 배지
  # 비노출: 이름(법적) / 이메일 / 스코어 / 크레딧
  def show
    @gen_week = ConnectRequest.current_gen_week
    pool_ids  = User.matching_pool_for(Current.user, gen_week: @gen_week).pluck(:id)

    unless pool_ids.include?(params[:id].to_i)
      redirect_to matching_path, alert: "현재 매칭 풀에서 볼 수 없는 사용자입니다." and return
    end

    @candidate    = User.find(params[:id])
    @invitation   = @candidate.invited_by&.sent_invitations&.find_by(accepted_by_id: @candidate.id)
    @my_pending   = Current.user.sent_connect_requests.find_by(gen_week: @gen_week, status: :pending)

    MatchExposure.find_or_create_by(viewer: Current.user, target: @candidate)
  end

  private
    def ensure_matching_active
      return if Current.user&.matching_active?
      redirect_to matching_path, alert: "매칭이 활성화되지 않았습니다."
    end
end
