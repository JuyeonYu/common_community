class AddReadCheckPaidToChatMessages < ActiveRecord::Migration[8.1]
  def change
    # 발신자가 5크레딧으로 본인 메시지의 read_at 노출 권한 구매 — Phase F-2-c.
    add_column :chat_messages, :read_check_paid, :boolean, default: false, null: false
  end
end
