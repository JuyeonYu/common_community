class MatchingController < ApplicationController
  BASE_POOL_SIZE = 5
  EXTRA_PER_PURCHASE = 5

  def show
    @missing_fields    = Current.user.matching_missing_fields
    @profile_complete  = @missing_fields.empty?
    @has_recommendation = Current.user.has_recommendation?
    @can_activate      = @profile_complete && @has_recommendation
    @accepted_invitation = Current.user.accepted_invitation
    return unless Current.user.matching_active?

    @gen_week = ConnectRequest.current_gen_week
    @pool_size = pool_size_for(Current.user, @gen_week)
    @candidates = build_candidates(Current.user, @gen_week, @pool_size)
    record_exposures(@candidates)
    @my_pending_request = Current.user.sent_connect_requests
                                .where(gen_week: @gen_week, status: :pending).first
    @received_requests = Current.user.recv_connect_requests
                                .where(gen_week: @gen_week, status: :pending)
                                .includes(:requester)
  end

  def enable
    unless Current.user.matching_ready?
      redirect_to matching_path, alert: "활성화 조건을 모두 충족해주세요." and return
    end
    Current.user.enable_matching!
    redirect_to matching_path, notice: "이성 매칭이 활성화되었습니다."
  end

  def destroy
    Current.user.disable_matching!
    redirect_to matching_path, notice: "이성 매칭을 일시 중지했습니다. 미수락 요청은 취소되었습니다."
  end

  # 새로고침 — 10 크레딧 차감, 본인의 모든 MatchExposure 삭제 후 풀 재추출.
  def refresh
    unless Current.user.matching_active?
      redirect_to matching_path, alert: "매칭이 활성화되지 않았습니다." and return
    end
    cost = Rails.application.config.x.blackticket.refresh_matching_cost
    if Current.user.ticket_credits < cost
      redirect_to matching_path,
        alert: "새로고침에 필요한 크레딧이 부족합니다 (#{cost} 필요)." and return
    end

    MatchingController.transaction_for_refresh(Current.user, cost)
    redirect_to matching_path, notice: "매칭 리스트를 새로고침했습니다 (-#{cost} 크레딧)."
  end

  def self.transaction_for_refresh(user, cost)
    ActiveRecord::Base.transaction do
      user.credit_transactions.create!(
        amount: -cost, kind: :spend, memo: "refresh_matching"
      )
      MatchExposure.where(viewer_id: user.id).delete_all
    end
  end

  # 추가 매칭권 — 12 크레딧 차감, 본 기수 풀 +5명 확장.
  def extend_pool
    unless Current.user.matching_active?
      redirect_to matching_path, alert: "매칭이 활성화되지 않았습니다." and return
    end
    cost = Rails.application.config.x.blackticket.extra_matching_cost
    if Current.user.ticket_credits < cost
      redirect_to matching_path,
        alert: "추가 매칭권에 필요한 크레딧이 부족합니다 (#{cost} 필요)." and return
    end

    Current.user.credit_transactions.create!(
      amount: -cost, kind: :spend, memo: "extra_matching"
    )
    redirect_to matching_path,
      notice: "후보 #{EXTRA_PER_PURCHASE}명을 추가했습니다 (-#{cost} 크레딧)."
  end

  private
    # 본 기수 기본 풀 + 추가 매칭권 구매당 +5명.
    def pool_size_for(user, gen_week)
      BASE_POOL_SIZE + user.extra_matchings_this_week_count(gen_week) * EXTRA_PER_PURCHASE
    end

    # 우선순위 정렬: ① 노출 없음 ② 동일 시·도. 그 외 무작위.
    # 작은 풀이라 Ruby 정렬로 충분.
    def build_candidates(viewer, gen_week, pool_size)
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
        .first(pool_size)
    end

    def record_exposures(candidates)
      candidates.each do |target|
        MatchExposure.find_or_create_by(viewer: Current.user, target: target)
      end
    end
end
