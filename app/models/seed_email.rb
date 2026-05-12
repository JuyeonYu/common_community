class SeedEmail < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  normalizes :email, with: ->(e) { e.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  def self.whitelisted?(email)
    exists?(email: email.to_s.strip.downcase)
  end
end
