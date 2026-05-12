class User < ApplicationRecord
  has_secure_password validations: false
  has_one_attached :avatar
  has_many :sessions, dependent: :destroy
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :acted_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :nullify
  has_many :push_subscriptions, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :inviter_id, dependent: :destroy
  belongs_to :invited_by, class_name: "User", optional: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :name, presence: true
  validates :google_uid, uniqueness: true, allow_nil: true
  validates :password, confirmation: true, length: { maximum: 72 }, allow_nil: true

  # Google OAuth 콜백 사용자 처리.
  # 신규 사용자라면 시드 화이트리스트 여부를 확인해 자동 활성화.
  def self.from_google_oauth(auth)
    user = find_or_initialize_by(google_uid: auth.uid)
    user.email_address = auth.info.email
    user.name = auth.info.name.presence || auth.info.email.to_s.split("@").first
    user.avatar_url = auth.info.image
    if user.new_record? && SeedEmail.whitelisted?(user.email_address)
      user.seed = true
      user.invitation_accepted_at = Time.current
    end
    user.save!
    user
  end

  # 활성 사용자 = 초대 코드를 적용했거나 시드 화이트리스트로 가입.
  def active?
    seed? || invitation_accepted_at.present?
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
