# 블랙티켓 운영 정책 상수.
# 운영 중 자주 조정되는 수치를 한 곳에 모아 변경 비용 최소화.
# 향후 admin UI(Setting 모델)로 옮길 수 있도록 키 구조 유지.
Rails.application.config.x.blackticket = ActiveSupport::OrderedOptions.new.tap do |c|
  # 신뢰/경제
  c.signup_bonus_credits      = 10
  c.boosted_invitation_cost   = 3
  c.downvote_penalty          = -1     # 1회당. "허위/언어" 사유만 적용
  c.suspension_period         = 1.month

  # 초대
  c.invitation_ttl            = 12.hours
  c.invitation_free_interval  = 7.days

  # 매칭/커넥트 (Phase D-2/3에서 사용)
  c.red_connect_default_ttl   = 1.month

  # 거절된 후 같은 기수 내 다른 후보에게 1회 추가 요청 가능 — 1 크레딧 소비.
  c.connect_retry_cost        = 1
end
