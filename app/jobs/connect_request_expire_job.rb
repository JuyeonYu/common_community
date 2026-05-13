class ConnectRequestExpireJob < ApplicationJob
  queue_as :default

  # 새 기수 시작 시 호출. 이전 기수의 미응답 pending 요청을 expired 처리.
  def perform
    current_week = ConnectRequest.current_gen_week
    ConnectRequest.where(status: :pending)
                  .where.not(gen_week: current_week)
                  .update_all(status: ConnectRequest.statuses[:expired])
  end
end
