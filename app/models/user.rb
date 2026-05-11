class User < ApplicationRecord
  has_secure_password validations: false
  has_one_attached :avatar
  has_many :sessions, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :filed_reports, class_name: "Report", foreign_key: :reporter_id, dependent: :destroy
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :acted_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :nullify
  has_many :push_subscriptions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :name, presence: true
  validates :google_uid, uniqueness: true, allow_nil: true
  validates :password, confirmation: true, length: { maximum: 72 }, allow_nil: true

  def self.from_google_oauth(auth)
    user = find_or_initialize_by(google_uid: auth.uid)
    user.email_address = auth.info.email
    user.name = auth.info.name.presence || auth.info.email.to_s.split("@").first
    user.avatar_url = auth.info.image
    user.save!
    user
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
