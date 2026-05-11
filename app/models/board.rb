class Board < ApplicationRecord
  has_many :posts, dependent: :restrict_with_error

  enum :write_permission, { everyone: 0, admin_only: 1 }, prefix: :write

  before_validation :set_slug

  validates :name, presence: true, uniqueness: true, length: { maximum: 30 }
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9_\-]+\z/, message: "는 영소문자/숫자/_/- 만 가능합니다" }
  validates :description, length: { maximum: 500 }
  validate  :allowed_prefixes_must_be_array_of_strings

  scope :ordered, -> { order(:position, :id) }
  scope :writable_by, ->(user) {
    user&.admin? ? all : where(write_permission: write_permissions[:everyone])
  }

  def to_param
    slug
  end

  def writable_by?(user)
    return true if write_everyone?
    user&.admin?
  end

  private
    def set_slug
      return if slug.present?
      return if name.blank?
      base = name.downcase.gsub(/\s+/, "-").gsub(/[^a-z0-9_\-]/, "")
      base = "board" if base.blank?
      candidate = base
      n = 1
      while Board.where.not(id: id).exists?(slug: candidate)
        n += 1
        candidate = "#{base}-#{n}"
      end
      self.slug = candidate
    end

    def allowed_prefixes_must_be_array_of_strings
      return if allowed_prefixes.is_a?(Array) &&
                allowed_prefixes.all? { |p| p.is_a?(String) && p.strip.present? }
      errors.add(:allowed_prefixes, "는 빈 문자열이 아닌 문자열 배열이어야 합니다")
    end
end
