class Comment < ApplicationRecord
  include Likeable
  include Reportable
  include Mentionable

  belongs_to :post
  belongs_to :user
  belongs_to :parent, optional: true, class_name: "Comment"
  has_many :replies, -> { order(:created_at) },
    foreign_key: :parent_id, class_name: "Comment", dependent: :destroy, inverse_of: :parent

  enum :status, { published: 0, hidden: 1 }

  validates :body, presence: true, length: { maximum: 2_000 }
  validate  :parent_must_be_top_level
  validate  :parent_must_belong_to_same_post

  scope :top_level, -> { where(parent_id: nil) }
  scope :recent,    -> { order(created_at: :desc) }
  scope :oldest,    -> { order(created_at: :asc) }

  after_create_commit :create_notification

  def reply?
    parent_id.present?
  end

  def author?(other_user)
    other_user.present? && user_id == other_user.id
  end

  # Mentionable concern 인터페이스 — 멘션 파싱 대상 텍스트와 그룹키(부모 글 단위).
  def mention_source_text
    body
  end

  def mention_group_key
    "post:#{post_id}:mention"
  end

  private
    def parent_must_be_top_level
      return if parent.blank?
      errors.add(:parent, "대댓글에는 답글을 달 수 없습니다") if parent.parent_id.present?
    end

    def parent_must_belong_to_same_post
      return if parent.blank?
      errors.add(:parent, "이 글의 댓글이 아닙니다") if parent.post_id != post_id
    end

    def create_notification
      if reply?
        return if parent.user_id == user_id
        Notification.deliver(recipient: parent.user, actor: user, action: "replied_to_comment",
                             notifiable: self, group_key: "comment:#{parent_id}:reply")
      else
        return if post.user_id == user_id
        Notification.deliver(recipient: post.user, actor: user, action: "commented_on_post",
                             notifiable: self, group_key: "post:#{post_id}:comment")
      end
    end
end
