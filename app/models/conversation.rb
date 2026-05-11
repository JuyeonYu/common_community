class Conversation < ApplicationRecord
  belongs_to :user_one, class_name: "User"
  belongs_to :user_two, class_name: "User"
  has_many :messages, dependent: :destroy

  validate :users_must_be_distinct

  scope :recent, -> { order(last_message_at: :desc, created_at: :desc) }

  # 두 사용자 사이의 대화방을 보장(작은 user_id가 항상 user_one_id).
  # 자기 자신과의 대화는 거부.
  def self.find_or_create_for(a, b)
    raise ArgumentError, "자기 자신과 대화할 수 없습니다" if a.id == b.id
    one, two = [ a, b ].sort_by(&:id)
    find_or_create_by!(user_one_id: one.id, user_two_id: two.id)
  end

  # user가 참가자인지
  def participant?(user)
    return false if user.blank?
    user.id == user_one_id || user.id == user_two_id
  end

  # user 입장에서 상대방
  def other_for(user)
    return nil unless participant?(user)
    user.id == user_one_id ? user_two : user_one
  end

  # user 입장에서 마지막 읽은 시각
  def last_read_at_for(user)
    return nil unless participant?(user)
    user.id == user_one_id ? user_one_last_read_at : user_two_last_read_at
  end

  # user를 위한 미읽 메시지 수 (본인이 보낸 것 제외)
  def unread_count_for(user)
    return 0 unless participant?(user)
    last_read = last_read_at_for(user)
    scope = messages.status_visible.where.not(sender_id: user.id)
    scope = scope.where("created_at > ?", last_read) if last_read
    scope.count
  end

  # user 진입 시 해당 컬럼을 현재 시각으로 갱신
  def mark_read_for(user)
    return false unless participant?(user)
    column = user.id == user_one_id ? :user_one_last_read_at : :user_two_last_read_at
    update_column(column, Time.current)
  end

  private
    def users_must_be_distinct
      errors.add(:base, "동일 사용자와 대화방 불가") if user_one_id.present? && user_one_id == user_two_id
    end
end
