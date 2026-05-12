class Post < ApplicationRecord
  include Likeable
  include Reportable

  belongs_to :user
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :comments, dependent: :destroy

  has_rich_text :body

  enum :status, { published: 0, hidden: 1 }

  validates :title, presence: true, length: { maximum: 200 }
  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_feed, -> { published.includes(:user, :tags).with_rich_text_body }

  def author?(other_user)
    other_user.present? && user_id == other_user.id
  end

  def tag_names
    tags.map(&:name).join(", ")
  end

  def tag_names=(value)
    self.tags = Tag.from_names(value)
  end
end
