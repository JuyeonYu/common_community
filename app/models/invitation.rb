class Invitation < ApplicationRecord
  TTL = 12.hours

  belongs_to :inviter, class_name: "User"
  belongs_to :accepted_user, class_name: "User", optional: true

  before_validation :generate_token, on: :create
  before_validation :set_expires_at, on: :create

  validates :token, presence: true, uniqueness: true
  validates :invitee_name, presence: true, length: { maximum: 30 }
  validates :invitee_phone, presence: true
  validates :invitee_email, presence: true
  validates :expires_at, presence: true

  scope :active, -> {
    where(accepted_at: nil, canceled_at: nil).where("expires_at > ?", Time.current)
  }

  def to_param
    token
  end

  def status
    return :canceled if canceled_at.present?
    return :accepted if accepted_at.present?
    return :expired  if expires_at <= Time.current
    :active
  end

  def active?
    status == :active
  end

  def cancel!
    return false if accepted_at.present?
    update!(canceled_at: Time.current)
  end

  def accept!(user)
    update!(accepted_at: Time.current, accepted_user: user)
  end

  private
    def generate_token
      return if token.present?
      loop do
        candidate = SecureRandom.urlsafe_base64(24)
        unless self.class.where(token: candidate).exists?
          self.token = candidate
          break
        end
      end
    end

    def set_expires_at
      self.expires_at ||= TTL.from_now
    end
end
