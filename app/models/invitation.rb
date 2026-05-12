class Invitation < ApplicationRecord
  # 사용자 입력용 코드에서 헷갈리는 글자(0/O/1/I/l) 제외.
  CODE_ALPHABET = (("A".."Z").to_a + ("2".."9").to_a - %w[ O I ]).freeze
  CODE_LENGTH   = 8

  belongs_to :inviter, class_name: "User"
  belongs_to :accepted_by, class_name: "User", optional: true

  enum :status, { pending: 0, accepted: 1, expired: 2, cancelled: 3 }

  validates :token, presence: true, uniqueness: true
  validates :code,  presence: true, uniqueness: true
  validates :expires_at, presence: true
  # 추천서는 발급 시점에 필수. 평생 따라다니며 신중 작성 의무.
  validates :recommendation_comment, presence: true, length: { in: 5..1000 }
  validate  :recommendation_comment_immutable

  before_validation :assign_code_and_token, on: :create
  before_validation :assign_expires_at,    on: :create

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
      self.expires_at ||= Rails.application.config.x.blackticket.invitation_ttl.from_now
    end

    # 추천서는 발급 시점에 한 번만 작성. 이후 수정 금지.
    def recommendation_comment_immutable
      return if new_record?
      return unless recommendation_comment_changed?
      errors.add(:recommendation_comment, "는 발급 후 수정할 수 없습니다")
    end
end
