class BlacklistEntry < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  normalizes :name,  with: ->(v) { v.to_s.strip }
  normalizes :phone, with: ->(v) { v.to_s.gsub(/[^\d]/, "") }

  validates :name,   presence: true, length: { maximum: 30 }
  validates :phone,  presence: true
  validates :reason, length: { maximum: 500 }
  validates :name,   uniqueness: { scope: :phone, message: "+ 휴대폰 조합이 이미 등록됨" }

  def self.matches?(name:, phone:)
    normalized_name  = name.to_s.strip
    normalized_phone = phone.to_s.gsub(/[^\d]/, "")
    where(name: normalized_name, phone: normalized_phone).exists?
  end
end
