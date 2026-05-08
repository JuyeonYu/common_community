module Likeable
  extend ActiveSupport::Concern

  included do
    has_many :likes, as: :likeable, dependent: :destroy
  end

  def liked_by?(user)
    return false if user.blank?
    likes.exists?(user_id: user.id)
  end

  def likes_count
    likes.size
  end
end
