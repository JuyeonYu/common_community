class Invitation < ApplicationRecord
  # 사용자 입력용 코드에서 헷갈리는 글자(0/O/1/I/l) 제외.
  CODE_ALPHABET = (("A".."Z").to_a + ("2".."9").to_a - %w[ O I ]).freeze
  CODE_LENGTH   = 8
  DEFAULT_TTL   = 12.hours

  belongs_to :inviter, class_name: "User"
  belongs_to :accepted_by, class_name: "User", optional: true

  enum :status, { pending: 0, accepted: 1, expired: 2, cancelled: 3 }

  validates :token, presence: true, uniqueness: true
  validates :code,  presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :assign_code_and_token, on: :create
  before_validation :assign_expires_at, on: :create

  scope :usable, -> { where(status: :pending).where("expires_at > ?", Time.current) }

  def usable?
    pending? && expires_at.future?
  end

  # 신규 가입자가 코드를 적용한 순간 호출. 1회용이라 accepted로 마킹.
  def redeem!(by_user)
    transaction do
      update!(status: :accepted, accepted_by: by_user)
      by_user.update!(invitation_accepted_at: Time.current, invited_by: inviter)
    end
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
      self.expires_at ||= DEFAULT_TTL.from_now
    end
end
