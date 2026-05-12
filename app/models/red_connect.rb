class RedConnect < ApplicationRecord
  belongs_to :user_a, class_name: "User"
  belongs_to :user_b, class_name: "User"

  enum :status, { active: 0, released: 1, expired: 2 }

  validate :user_a_less_than_user_b
  before_validation :normalize_user_pair, on: :create

  scope :between, ->(u1, u2) {
    a, b = [ u1.id, u2.id ].sort
    where(user_a_id: a, user_b_id: b)
  }

  scope :for_user, ->(user) {
    where("user_a_id = :id OR user_b_id = :id", id: user.id)
  }

  def other_user(user)
    user.id == user_a_id ? user_b : user_a
  end

  def release!(reason: nil)
    update!(status: :released, release_reason: reason)
  end

  def expire!
    update!(status: :expired)
  end

  private
    # 항상 id 작은 쪽이 user_a 가 되도록 정렬 (unique pair).
    def normalize_user_pair
      return if user_a_id.blank? || user_b_id.blank?
      if user_a_id > user_b_id
        self.user_a_id, self.user_b_id = user_b_id, user_a_id
      end
    end

    def user_a_less_than_user_b
      return if user_a_id.blank? || user_b_id.blank?
      errors.add(:user_b_id, "은 자기 자신일 수 없습니다") if user_a_id == user_b_id
    end
end
