class EmailOtp < ApplicationRecord
  CODE_LENGTH = 6
  TTL = 10.minutes

  validates :email, presence: true
  validates :code, presence: true
  validates :expires_at, presence: true

  normalizes :email, with: ->(e) { e.to_s.strip.downcase }

  scope :for_email,   ->(email) { where(email: email.to_s.strip.downcase) }
  scope :unconsumed,  -> { where(consumed_at: nil) }
  scope :unexpired,   -> { where("expires_at > ?", Time.current) }

  # 새 OTP 발급. 같은 이메일에 기존 미사용 OTP가 있어도 새로 발급(이전은 verify 시 무시).
  def self.issue(email)
    code = rand(10**CODE_LENGTH).to_s.rjust(CODE_LENGTH, "0")
    create!(email: email, code: code, expires_at: TTL.from_now)
  end

  # 이메일과 코드로 검증. 성공 시 해당 row를 consumed 처리.
  # 성공/실패만 반환.
  def self.verify(email:, code:)
    record = for_email(email).unconsumed.unexpired.where(code: code).order(created_at: :desc).first
    return false unless record
    record.update!(consumed_at: Time.current)
    true
  end
end
