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
    @highlighted_user_ids = highlighted_user_ids(@gen_week)
    @candidates = build_candidates(Current.user, @gen_week, @pool_size, @highlighted_user_ids)
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

  # 프로필 우선 노출 — 30 크레딧, 24h 동안 다른 사용자의 매칭 풀에서 본인 우선 정렬.
  def boost_profile
    if Current.user.profile_boosted?
      redirect_to matching_path,
        notice: "프로필 우선 노출이 #{l Current.user.boosted_until, format: :short}까지 적용 중입니다." and return
    end
    cost = Rails.application.config.x.blackticket.profile_boost_cost
    ttl  = Rails.application.config.x.blackticket.profile_boost_ttl
    if Current.user.ticket_credits < cost
      redirect_to matching_path,
        alert: "우선 노출에 필요한 크레딧이 부족합니다 (#{cost} 필요)." and return
    end

    User.transaction do
      Current.user.credit_transactions.create!(
        amount: -cost, kind: :spend, memo: "profile_boost"
      )
      Current.user.update!(boosted_until: Time.current + ttl)
    end
    redirect_to matching_path,
      notice: "프로필을 24시간 동안 우선 노출합니다 (-#{cost} 크레딧)."
  end

  # 거주지/직무 필터 해제 — 20 크레딧, 본 기수 동안 동일 지역 우선 정렬 무시.
  def unlock_filter
    unless Current.user.matching_active?
      redirect_to matching_path, alert: "매칭이 활성화되지 않았습니다." and return
    end
    gen_week = ConnectRequest.current_gen_week
    if Current.user.filter_unlocked_this_week?(gen_week)
      redirect_to matching_path, notice: "이번 기수에 이미 필터 해제가 적용되어 있습니다." and return
    end
    cost = Rails.application.config.x.blackticket.filter_unlock_cost
    if Current.user.ticket_credits < cost
      redirect_to matching_path,
        alert: "필터 해제에 필요한 크레딧이 부족합니다 (#{cost} 필요)." and return
    end

    Current.user.credit_transactions.create!(
      amount: -cost, kind: :spend, memo: "filter_unlock"
    )
    redirect_to matching_path,
      notice: "이번 기수 동안 거주지/직무 필터를 해제했습니다 (-#{cost} 크레딧)."
  end

  # 추천 코멘트 강조 — 15 크레딧, 본 기수 동안 매칭 카드 상위 노출 + 강조 배지.
  def highlight_recommendation
    invitation = Current.user.accepted_invitation
    unless invitation&.recommendation_written?
      redirect_to matching_path,
        alert: "강조할 추천서가 아직 없습니다." and return
    end
    gen_week = ConnectRequest.current_gen_week
    if Current.user.highlight_purchased_this_week?(gen_week)
      redirect_to matching_path, notice: "이번 기수에 이미 강조 표시가 적용되어 있습니다." and return
    end
    cost = Rails.application.config.x.blackticket.highlight_recommendation_cost
    if Current.user.ticket_credits < cost
      redirect_to matching_path,
        alert: "강조 표시에 필요한 크레딧이 부족합니다 (#{cost} 필요)." and return
    end

    Current.user.credit_transactions.create!(
      amount: -cost, kind: :spend, related: invitation, memo: "highlight_recommendation"
    )
    redirect_to matching_path,
      notice: "추천서를 이번 기수 동안 강조 표시합니다 (-#{cost} 크레딧)."
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

    # 본 기수에 추천서 강조를 산 사용자 id 셋 — 매칭 정렬 최우선.
    def highlighted_user_ids(gen_week)
      range = ConnectRequest.gen_week_range(gen_week)
      CreditTransaction.where(kind: :spend, memo: "highlight_recommendation", created_at: range)
                       .pluck(:user_id).to_set
    end

    # 우선순위 정렬:
    # ① 프로필 우선 노출 (boosted_until > now) — 결제 즉시성·최우선
    # ② 본 기수 추천서 강조 구매자
    # ③ 노출 없음
    # ④ 동일 시·도 (단, viewer가 본 기수 필터 해제를 구매했으면 무시)
    # ⑤ 무작위
    def build_candidates(viewer, gen_week, pool_size, highlighted_ids = Set.new)
      scope = User.matching_pool_for(viewer, gen_week: gen_week).with_attached_avatar
      exposed_ids = MatchExposure.where(viewer_id: viewer.id).pluck(:target_id).to_set
      filter_unlocked = viewer.filter_unlocked_this_week?(gen_week)
      now = Time.current

      scope.to_a
        .sort_by { |u|
          [
            (u.boosted_until.present? && u.boosted_until > now) ? 0 : 1,
            highlighted_ids.include?(u.id) ? 0 : 1,
            exposed_ids.include?(u.id) ? 1 : 0,
            filter_unlocked ? 0 : ((u.residence_area == viewer.residence_area) ? 0 : 1),
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
