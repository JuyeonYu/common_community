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
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :destroy
  has_many :conversations_as_one, class_name: "Conversation", foreign_key: :user_one_id, dependent: :destroy
  has_many :conversations_as_two, class_name: "Conversation", foreign_key: :user_two_id, dependent: :destroy
  has_many :blocks_made, class_name: "Block", foreign_key: :blocker_id, dependent: :destroy
  has_many :blocks_received, class_name: "Block", foreign_key: :blocked_id, dependent: :destroy

  belongs_to :inviter, class_name: "User", optional: true
  has_many :invited_users, class_name: "User", foreign_key: :inviter_id, dependent: :nullify
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :inviter_id, dependent: :destroy

  ADULT_AGE = 25

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :phone, with: ->(p) { p.to_s.gsub(/[^\d]/, "").presence }

  validates :email_address, presence: true, uniqueness: true
  validates :name, presence: true
  validates :google_uid, uniqueness: true, allow_nil: true
  validates :password, confirmation: true, length: { maximum: 72 }, allow_nil: true
  validates :phone, uniqueness: true, allow_nil: true

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

  def broadcast_messages_badge
    Turbo::StreamsChannel.broadcast_replace_to(
      [ self, :messages ],
      target: "messages_badge",
      partial: "shared/messages_badge",
      locals: { user: self }
    )
  end

  # 내가 참가자인 모든 conversation
  def conversations
    Conversation.where("user_one_id = ? OR user_two_id = ?", id, id)
  end

  def total_unread_messages_count
    conversations.includes(:messages).sum { |c| c.unread_count_for(self) }
  end

  def adult?
    return false if birthdate.blank?
    age >= ADULT_AGE
  end

  def age
    return nil if birthdate.blank?
    today = Date.current
    diff = today.year - birthdate.year
    diff -= 1 if today.strftime("%m%d") < birthdate.strftime("%m%d")
    diff
  end

  def suspended?
    suspended_at.present?
  end
end
