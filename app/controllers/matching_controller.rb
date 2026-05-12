class MatchingController < ApplicationController
  POOL_SIZE = 5

  def show
    @missing_fields = Current.user.matching_missing_fields
    @can_activate   = @missing_fields.empty?
    return unless Current.user.matching_active?

    @gen_week = ConnectRequest.current_gen_week
    @candidates = build_candidates(Current.user, @gen_week)
    record_exposures(@candidates)
    @my_pending_request = Current.user.sent_connect_requests
                                .where(gen_week: @gen_week, status: :pending).first
    @received_requests = Current.user.recv_connect_requests
                                .where(gen_week: @gen_week, status: :pending)
                                .includes(:requester)
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
    redirect_to matching_path, notice: "이성 매칭을 일시 중지했습니다. 미수락 요청은 취소되었습니다."
  end

  private
    # 우선순위 정렬: ① 노출 없음 ② 동일 시·도. 그 외 무작위.
    # 작은 풀이라 Ruby 정렬로 충분.
    def build_candidates(viewer, gen_week)
      scope = User.matching_pool_for(viewer, gen_week: gen_week).with_attached_avatar
      exposed_ids = MatchExposure.where(viewer_id: viewer.id).pluck(:target_id).to_set

      scope.to_a
        .sort_by { |u|
          [
            exposed_ids.include?(u.id) ? 1 : 0,
            (u.residence_area == viewer.residence_area) ? 0 : 1,
            SecureRandom.random_number
          ]
        }
        .first(POOL_SIZE)
    end

    def record_exposures(candidates)
      candidates.each do |target|
        MatchExposure.find_or_create_by(viewer: Current.user, target: target)
      end
    end
end
