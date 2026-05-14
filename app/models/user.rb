class User < ApplicationRecord
  # 거주지 — 한국 17개 광역시·도
  RESIDENCE_AREAS = {
    seoul:    0,
    busan:    1,
    daegu:    2,
    incheon:  3,
    gwangju:  4,
    daejeon:  5,
    ulsan:    6,
    sejong:   7,
    gyeonggi: 8,
    gangwon:  9,
    chungbuk: 10,
    chungnam: 11,
    jeonbuk:  12,
    jeonnam: 13,
    gyeongbuk: 14,
    gyeongnam: 15,
    jeju:     16
  }.freeze

  has_one_attached :avatar
  has_many :sessions, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :filed_reports, class_name: "Report", foreign_key: :reporter_id, dependent: :destroy
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :acted_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :nullify
  has_many :push_subscriptions, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :inviter_id, dependent: :destroy
  has_one  :accepted_invitation, class_name: "Invitation", foreign_key: :accepted_by_id
  has_many :score_events, dependent: :destroy
  has_many :credit_transactions, dependent: :destroy
  belongs_to :invited_by, class_name: "User", optional: true
  has_many :invitees, class_name: "User", foreign_key: :invited_by_id, dependent: :nullify

  has_many :sent_connect_requests,  class_name: "ConnectRequest", foreign_key: :requester_id, dependent: :destroy
  has_many :recv_connect_requests,  class_name: "ConnectRequest", foreign_key: :target_id,    dependent: :destroy
  has_many :chat_messages, foreign_key: :sender_id, dependent: :destroy

  def active_red_connects
    RedConnect.for_user(self).where(status: :active)
  end

  # chat_message 알림은 group_key("chat:<rcid>:<sender>")로 묶이므로 미확인 row 수 = 미확인 대화방 수.
  def unread_message_room_count
    notifications.unread.where(action: "chat_message").count
  end

  # 본 기수에 RedConnect를 한 번이라도 성사시킨 적이 있는지 (취소/해제와 무관).
  def had_red_connect_this_week?(gen_week)
    ConnectRequest.where(gen_week: gen_week, status: :accepted)
                  .where("requester_id = :id OR target_id = :id", id: id)
                  .exists?
  end

  # 본 기수에 사용한 재요청 크레딧 횟수 (memo: "connect_retry").
  def connect_retries_used_this_week(gen_week)
    range = ConnectRequest.gen_week_range(gen_week)
    credit_transactions.where(kind: :spend, memo: "connect_retry", created_at: range).count
  end

  enum :residence_area, RESIDENCE_AREAS
  enum :smoking,        { smokes: 0, non_smoker: 1, sometimes: 2 }
  enum :gender,         { male: 0, female: 1 }

  # 매칭 필수 프로필 필드. 누락 시 매칭 활성화 불가.
  MATCHING_REQUIRED_FIELDS = %i[ nickname birth_date gender residence_area job_title smoking hobby bio ].freeze

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :hobby, with: ->(value) {
    next nil if value.blank?
    tags = value.to_s.split(/[,\s]+/).reject(&:blank?).map { |t| t.delete_prefix("#") }.uniq
    next nil if tags.empty?
    tags.map { |t| "##{t}" }.join(" ")
  }

  validates :email_address, presence: true, uniqueness: true
  validates :name, presence: true
  # nickname은 controller before_action(ensure_nickname)이 강제. 모델 검증은 입력 값이 있을 때만 unique/length/format.
  validates :nickname, uniqueness: true, length: { in: 2..20 },
            format: { with: /\A[\p{L}\p{N}_]+\z/, message: "는 한글/영문/숫자/_만 사용할 수 있습니다" },
            if: -> { nickname.present? }
  validates :google_uid, uniqueness: true, allow_nil: true
  validates :ticket_score, numericality: { only_integer: true }
  validates :ticket_credits, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Google OAuth 콜백 사용자 처리.
  # 신규면 시드 화이트리스트 확인 + 가입 보너스 크레딧.
  def self.from_google_oauth(auth)
    user = find_or_initialize_by(google_uid: auth.uid)
    user.email_address = auth.info.email
    user.name = auth.info.name.presence || auth.info.email.to_s.split("@").first
    user.avatar_url = auth.info.image
    is_new = user.new_record?
    if is_new && SeedEmail.whitelisted?(user.email_address)
      user.seed = true
      user.invitation_accepted_at = Time.current
    end
    user.save!
    bonus = Rails.application.config.x.blackticket.signup_bonus_credits
    if is_new && bonus.positive?
      user.credit_transactions.create!(amount: bonus, kind: :signup_bonus, memo: "가입 보너스")
    end
    user
  end

  # 활성 사용자 = (초대 코드 적용 || 시드) && 정지 만료 후.
  def active?
    (seed? || invitation_accepted_at.present?) && !suspended?
  end

  def suspended?
    suspended_until.present? && suspended_until.future?
  end

  def suspend!(period: Rails.application.config.x.blackticket.suspension_period, reason: nil)
    update!(suspended_until: period.from_now)
  end

  # 매칭 활성화 조건 — 프로필 필수 필드 + 아바타.
  def matching_profile_complete?
    matching_missing_fields.empty?
  end

  def matching_missing_fields
    missing = MATCHING_REQUIRED_FIELDS.reject { |f| public_send(f).present? }
    missing << :avatar unless avatar.attached?
    missing
  end

  # 추천서 조건 — 시드 사용자는 면제, 일반은 초대장에 추천서가 작성돼 있어야 함.
  def has_recommendation?
    return true if seed?
    accepted_invitation&.recommendation_written?
  end

  def matching_ready?
    matching_profile_complete? && has_recommendation?
  end

  def matching_active?
    matching_enabled? && active?
  end

  def enable_matching!
    update!(matching_enabled: true, matching_activated_at: (matching_activated_at || Time.current))
  end

  def disable_matching!
    transaction do
      update!(matching_enabled: false)
      # 본인이 송수신한 pending ConnectRequest 일괄 취소 (휴식 진입 시 정리).
      ConnectRequest.where(status: :pending)
        .where("requester_id = :id OR target_id = :id", id: id)
        .find_each { |req| req.update!(status: :cancelled) }
    end
  end

  def gender_opposite
    return nil if gender.blank?
    male? ? "female" : "male"
  end

  # 매칭 풀 후보 — viewer 기준으로 본 추출 가능한 사용자.
  # 제외 조건: 본인, 비활성/정지, 동성, 이미 RedConnect 성사, 본인이 이번 기수에 이미 요청 송신/타깃
  def self.matching_pool_for(viewer, gen_week:)
    return none if viewer.gender.blank?

    pool = where(matching_enabled: true)
      .where("seed = TRUE OR invitation_accepted_at IS NOT NULL")
      .where("suspended_until IS NULL OR suspended_until <= ?", Time.current)
      .where(gender: viewer.gender_opposite)
      .where.not(id: viewer.id)

    # 이미 RedConnect 성사된 사용자 제외 (양쪽 어떤 슬롯에 있든)
    connected_ids = RedConnect.for_user(viewer).pluck(:user_a_id, :user_b_id).flatten.uniq
    pool = pool.where.not(id: connected_ids) if connected_ids.any?

    # 본인이 이번 기수에 송신한 요청의 target / 받은 요청의 requester 제외 (서로 한 번이면 의미 X)
    sent_target_ids = ConnectRequest.where(requester_id: viewer.id, gen_week: gen_week).pluck(:target_id)
    recv_req_ids    = ConnectRequest.where(target_id: viewer.id, gen_week: gen_week).pluck(:requester_id)
    excluded = (sent_target_ids + recv_req_ids).uniq
    pool = pool.where.not(id: excluded) if excluded.any?

    # 본 기수에 한 번이라도 RedConnect를 성사시킨 사용자(본인 포함 양방향) 제외 (Phase E-5)
    accepted_this_week = ConnectRequest.where(gen_week: gen_week, status: :accepted)
                                       .pluck(:requester_id, :target_id).flatten.uniq
    pool = pool.where.not(id: accepted_this_week) if accepted_this_week.any?

    pool
  end

  def unsuspend!
    update!(suspended_until: nil)
  end

  def age
    return nil if birth_date.blank?
    today = Date.current
    age = today.year - birth_date.year
    age -= 1 if today < birth_date + age.years
    age
  end

  def broadcast_notification_badge
    Turbo::StreamsChannel.broadcast_replace_to(
      [ self, :notifications ],
      target: "notification_badge",
      partial: "shared/notification_badge",
      locals: { user: self }
    )
  end

end
