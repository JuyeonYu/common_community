class Setting < ApplicationRecord
  # 운영 가변값 저장 — key/value 단일 테이블 패턴.
  # 사용처: 은행 계좌 정보(H-1), 향후 운영 공지/발신번호 등.

  validates :key, presence: true, uniqueness: true

  def self.get(key, default: nil)
    where(key: key.to_s).pick(:value) || default
  end

  def self.set(key, value)
    record = find_or_initialize_by(key: key.to_s)
    record.update!(value: value)
    record
  end
end
