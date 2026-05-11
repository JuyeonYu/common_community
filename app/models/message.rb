class Message < ApplicationRecord
  include Reportable

  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  has_many_attached :images

  enum :status, { visible: 0, hidden: 1 }, prefix: :status

  validates :body, length: { maximum: 2_000 }
  validate  :body_or_images_present
  validate  :acceptable_images
  validate  :sender_must_be_participant

  ALLOWED_IMAGE_TYPES = %w[ image/png image/jpeg image/webp image/gif ].freeze
  MAX_IMAGE_SIZE = 5.megabytes
  MAX_IMAGES = 5

  after_create_commit  :touch_conversation_last_message_at
  after_create_commit  :broadcast_to_conversation
  after_create_commit  :broadcast_to_participants_index
  after_destroy_commit :broadcast_removal
  after_destroy_commit :broadcast_to_participants_index

  scope :recent, -> { order(created_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }

  RECALL_WINDOW = 5.minutes

  def recallable_by?(user)
    return false unless sender_id == user&.id
    created_at > RECALL_WINDOW.ago
  end

  def recipient
    conversation.other_for(sender)
  end

  private
    def body_or_images_present
      return if body.present? || images.attached?
      errors.add(:base, "본문 또는 이미지를 입력하세요")
    end

    def acceptable_images
      return unless images.attached?

      if images.size > MAX_IMAGES
        errors.add(:images, "은 최대 #{MAX_IMAGES}장까지 가능합니다")
      end

      images.each do |image|
        unless image.content_type.in?(ALLOWED_IMAGE_TYPES)
          errors.add(:images, "은 PNG/JPEG/WEBP/GIF만 가능합니다")
          break
        end
        if image.byte_size > MAX_IMAGE_SIZE
          errors.add(:images, "은 #{MAX_IMAGE_SIZE / 1.megabyte}MB 이하여야 합니다")
          break
        end
      end
    end

    def sender_must_be_participant
      return if conversation.blank? || sender.blank?
      errors.add(:sender, "이 대화방의 참가자가 아닙니다") unless conversation.participant?(sender)
    end

    def touch_conversation_last_message_at
      conversation.update_column(:last_message_at, created_at)
    end

    def broadcast_to_conversation
      broadcast_append_to [ conversation, :messages ],
        target: "messages_list",
        partial: "messages/message",
        locals: { message: self }

      recipient&.broadcast_messages_badge
    end

    def broadcast_removal
      broadcast_remove_to [ conversation, :messages ]
      recipient&.broadcast_messages_badge
    end

    # 양쪽 참가자의 /conversations 카드 갱신: remove + prepend로 최상단 이동.
    # 카드가 없으면 prepend만 적용됨(remove는 silently no-op).
    def broadcast_to_participants_index
      [ conversation.user_one, conversation.user_two ].each do |user|
        Turbo::StreamsChannel.broadcast_remove_to(
          [ user, :conversations ],
          target: ActionView::RecordIdentifier.dom_id(conversation)
        )
        Turbo::StreamsChannel.broadcast_prepend_to(
          [ user, :conversations ],
          target: "conversations_list",
          partial: "conversations/conversation",
          locals: { conversation: conversation, viewer: user }
        )
      end
    end
end
