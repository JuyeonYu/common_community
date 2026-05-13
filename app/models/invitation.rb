class Invitation < ApplicationRecord
  # 사용자 입력용 코드에서 헷갈리는 글자(0/O/1/I/l) 제외.
  CODE_ALPHABET = (("A".."Z").to_a + ("2".."9").to_a - %w[ O I ]).freeze
  CODE_LENGTH   = 8

  belongs_to :inviter, class_name: "User"
  belongs_to :accepted_by, class_name: "User", optional: true

  enum :status, { pending: 0, accepted: 1, expired: 2, cancelled: 3 }

  normalizes :invitee_email, with: ->(v) { v.to_s.strip.downcase }

  validates :token, presence: true, uniqueness: true
  validates :code,  presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :invitee_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate  :invitee_not_already_user, on: :create
  # 추천서는 발급 후 별도로 작성. 작성된 길이 제약.
  validates :recommendation_comment, length: { in: 5..1000 }, allow_blank: true
  validate  :recommendation_comment_immutable_after_first_write

  before_validation :assign_code_and_token, on: :create
  before_validation :assign_expires_at,    on: :create

  scope :usable, -> { where(status: :pending).where("expires_at > ?", Time.current) }

  def usable?
    pending? && expires_at.future?
  end

  # 신규 가입자가 코드를 적용한 순간 호출. 1회용이라 accepted로 마킹.
  # 초대 이메일과 가입자 이메일이 정확히 일치해야 한다(소문자 무시).
  # 일치하지 않으면 EmailMismatch 예외.
  def redeem!(by_user)
    if invitee_email.present? && by_user.email_address.to_s.downcase != invitee_email
      raise EmailMismatch, "초대받은 이메일과 일치하지 않습니다"
    end
    transaction do
      update!(status: :accepted, accepted_by: by_user)
      by_user.update!(invitation_accepted_at: Time.current, invited_by: inviter)
    end
  end

  class EmailMismatch < StandardError; end

  def matches_email?(email)
    invitee_email.present? && email.to_s.strip.downcase == invitee_email
  end

  def recommendation_written?
    recommendation_comment.present?
  end

  def cancel!
    update!(status: :cancelled)
  end

  private
    def assign_code_and_token
      return if code.present?
      loop do
        candidate = Array.new(CODE_LENGTH) { CODE_ALPHABET.sample }.join
        unless self.class.exists?(code: candidate)
          self.code  = candidate
          self.token = candidate
          break
        end
      end
    end

    def assign_expires_at
      self.expires_at ||= Rails.application.config.x.blackticket.invitation_ttl.from_now
    end

    # 추천서는 발급 후 사후 작성. 첫 작성 후엔 수정 금지(빈→값은 허용, 값→다른값/빈은 금지).
    def recommendation_comment_immutable_after_first_write
      return if new_record?
      return unless recommendation_comment_changed?
      return if recommendation_comment_was.blank? && recommendation_comment.present?
      errors.add(:recommendation_comment, "는 한 번 작성한 후 수정할 수 없습니다")
    end

    # 이미 가입한 이메일로는 초대 발급 불가.
    def invitee_not_already_user
      return if invitee_email.blank?
      if User.where("LOWER(email_address) = ?", invitee_email).exists?
        errors.add(:invitee_email, "은 이미 가입된 사용자입니다")
      end
    end
end
