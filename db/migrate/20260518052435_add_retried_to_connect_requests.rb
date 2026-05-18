class AddRetriedToConnectRequests < ActiveRecord::Migration[8.1]
  def change
    # 재요청 식별 — 거절 시 50% 환급 대상을 표시 (Phase F-2-a).
    add_column :connect_requests, :retried, :boolean, default: false, null: false
  end
end
