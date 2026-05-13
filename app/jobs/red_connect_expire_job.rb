class RedConnectExpireJob < ApplicationJob
  queue_as :default

  # 만료 시각 지난 active RedConnect를 expired로 마킹.
  # release와 달리 release_reason은 미설정 — UI에서 만료/해제 구분.
  def perform
    RedConnect.where(status: :active)
              .where("expires_at < ?", Time.current)
              .update_all(status: RedConnect.statuses[:expired])
  end
end
