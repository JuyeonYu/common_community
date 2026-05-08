class Tag < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  before_validation :set_slug

  validates :name, presence: true, uniqueness: true, length: { maximum: 30 }
  validates :slug, presence: true, uniqueness: true

  scope :ordered, -> { order(name: :asc) }

  def to_param
    slug
  end

  # 콤마(,) 또는 한글 콤마(，)로 구분된 문자열에서 Tag 컬렉션 반환.
  # 존재하지 않는 태그는 새로 만든다.
  def self.from_names(value)
    names = value.to_s.split(/[,，]/).map { |n| n.strip.downcase }.reject(&:blank?).uniq
    names.map { |name| find_or_create_by!(name: name) }
  end

  private
    def set_slug
      return if name.blank?
      self.slug = name.downcase.strip.gsub(/\s+/, "-").gsub(/[^\p{Alnum}\-]/, "")
      self.slug = "tag-#{SecureRandom.hex(3)}" if slug.blank?
    end
end
