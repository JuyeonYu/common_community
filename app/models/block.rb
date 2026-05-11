class Block < ApplicationRecord
  belongs_to :blocker, class_name: "User"
  belongs_to :blocked, class_name: "User"

  validates :reason, length: { maximum: 500 }
  validates :blocker_id, uniqueness: { scope: :blocked_id }
  validate  :blocker_blocked_distinct

  # 두 사용자 사이에 차단이 존재하는지 (양방향)
  def self.exists_between?(a, b)
    return false if a.blank? || b.blank? || a.id == b.id
    where("(blocker_id = ? AND blocked_id = ?) OR (blocker_id = ? AND blocked_id = ?)",
          a.id, b.id, b.id, a.id).exists?
  end

  private
    def blocker_blocked_distinct
      errors.add(:base, "자기 자신을 차단할 수 없습니다") if blocker_id.present? && blocker_id == blocked_id
    end
end
