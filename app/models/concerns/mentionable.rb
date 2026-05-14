module Mentionable
  extend ActiveSupport::Concern

  # 본문에서 @닉네임 추출 → 해당 사용자에게 mentioned 알림.
  # 한 알림은 게시글 단위(post:<id>:mention)로 그룹화 — 같은 사람을 같은 글에서 여러 번 멘션해도 count만 증가.

  MENTION_REGEX = /@([\p{L}\p{N}_]{2,20})/

  included do
    after_create_commit :notify_mentions
  end

  private
    def notify_mentions
      return unless respond_to?(:mention_source_text)
      nicknames = mention_source_text.to_s.scan(MENTION_REGEX).flatten.uniq
      return if nicknames.empty?

      User.where(nickname: nicknames).where.not(id: user_id).find_each do |target|
        Notification.deliver(
          recipient: target, actor: user, action: "mentioned",
          notifiable: self, group_key: mention_group_key
        )
      end
    end
end
