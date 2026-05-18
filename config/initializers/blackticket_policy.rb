# 블랙티켓 운영 정책 상수.
# 운영 중 자주 조정되는 수치를 한 곳에 모아 변경 비용 최소화.
# 크레딧 소비량은 상위기획서 v1.2 7장 가격 정책 기준.
# 향후 admin UI(Setting 모델)로 옮길 수 있도록 키 구조 유지.
Rails.application.config.x.blackticket = ActiveSupport::OrderedOptions.new.tap do |c|
  # 신뢰/경제
  c.signup_bonus_credits      = 10
  c.boosted_invitation_cost   = 25     # 적극 추천 — v1.2 7-4
  c.downvote_penalty          = -1     # 1회당. "허위/언어" 사유만 적용
  c.suspension_period         = 1.month

  # 초대
  c.invitation_ttl            = 12.hours
  c.invitation_free_interval  = 7.days
  c.invitation_extra_cost     = 40     # 7일 무료 외 추가 발급 — v1.2 7-4. 사용처 Phase F-2

  # 매칭/커넥트
  c.red_connect_default_ttl   = 1.month
  c.connect_retry_cost        = 30     # 거절 후 다른 후보 재요청 — v1.2 7-4
  c.extra_matching_cost       = 12     # 추가 매칭권(+5명) — v1.2 7-4
  c.red_connect_extension_cost = 60    # 커넥트 연장권(+1개월) — v1.2 7-4
  c.refresh_matching_cost     = 10     # 매칭 리스트 새로고침 — v1.2 7-5
  c.highlight_recommendation_cost = 15 # 추천 코멘트 강조 (1기수) — v1.2 7-5
  c.filter_unlock_cost        = 20     # 거주지/직무 필터 해제 (1기수) — v1.2 7-5
  c.profile_boost_cost        = 30     # 프로필 우선 노출 (24h) — v1.2 7-5
  c.profile_boost_ttl         = 24.hours
  c.chat_read_receipt_cost    = 5      # 채팅 읽음 확인 (1건) — v1.2 7-5
end
