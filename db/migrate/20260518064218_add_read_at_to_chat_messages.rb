class AddReadAtToChatMessages < ActiveRecord::Migration[8.1]
  def change
    # 발신자가 5크레딧으로 본인 메시지의 수신자 읽음 여부 확인 — Phase F-2-c.
    add_column :chat_messages, :read_at, :datetime
  end
end
