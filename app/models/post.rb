class Post < ApplicationRecord
  include Likeable
  include Reportable
  include PgSearch::Model

  belongs_to :user
  belongs_to :board
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :comments, dependent: :destroy

  has_rich_text :body

  pg_search_scope :search_by_text,
    against: { title: "A" },
    associated_against: { rich_text_body: { body: "B" } },
    using: {
      tsearch: { prefix: true, dictionary: "simple" },
      trigram: { threshold: 0.2 }
    }

  enum :status, { published: 0, hidden: 1 }

  validates :title, presence: true, length: { maximum: 200 }
  validates :body, presence: true
  validate  :prefix_must_be_allowed

  scope :recent, -> { order(created_at: :desc) }
  scope :for_feed, -> { published.includes(:user, :board, :tags).with_rich_text_body }

  def author?(other_user)
    other_user.present? && user_id == other_user.id
  end

  def tag_names
    tags.map(&:name).join(", ")
  end

  def tag_names=(value)
    self.tags = Tag.from_names(value)
  end

  private
    def prefix_must_be_allowed
      return if prefix.blank?
      return if board && board.allowed_prefixes.include?(prefix)
      errors.add(:prefix, "는 이 게시판의 말머리 목록에 없습니다")
    end
end
