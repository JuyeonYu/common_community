class User < ApplicationRecord
  SIGNUP_BONUS_CREDITS = 10
  SUSPENSION_PERIOD = 1.month

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

  has_secure_password validations: false
  has_one_attached :avatar
  has_many :sessions, dependent: :destroy
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :acted_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :nullify
  has_many :push_subscriptions, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :inviter_id, dependent: :destroy
  has_many :score_events, dependent: :destroy
  has_many :credit_transactions, dependent: :destroy
  belongs_to :invited_by, class_name: "User", optional: true
  has_many :invitees, class_name: "User", foreign_key: :invited_by_id, dependent: :nullify

  enum :residence_area, RESIDENCE_AREAS
  enum :smoking,        { smokes: 0, non_smoker: 1, sometimes: 2 }
  enum :gender,         { male: 0, female: 1, other: 2 }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :hobby, with: ->(value) {
    next nil if value.blank?
    tags = value.to_s.split(/[,\s]+/).reject(&:blank?).map { |t| t.delete_prefix("#") }.uniq
    next nil if tags.empty?
    tags.map { |t| "##{t}" }.join(" ")
  }

  validates :email_address, presence: true, uniqueness: true
  validates :name, presence: true
  validates :nickname, uniqueness: true, allow_nil: true,
            length: { in: 2..20 },
            format: { with: /\A[\p{L}\p{N}_]+\z/, message: "는 한글/영문/숫자/_만 사용할 수 있습니다" },
            if: -> { nickname.present? }
  validates :google_uid, uniqueness: true, allow_nil: true
  validates :password, confirmation: true, length: { maximum: 72 }, allow_nil: true
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
    if is_new && SIGNUP_BONUS_CREDITS.positive?
      user.credit_transactions.create!(amount: SIGNUP_BONUS_CREDITS, kind: :signup_bonus,
                                       memo: "가입 보너스")
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

  def suspend!(period: SUSPENSION_PERIOD, reason: nil)
    update!(suspended_until: period.from_now)
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
