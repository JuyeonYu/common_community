# 크레딧 결제 패키지 — 상위기획서 v1.2 7-3 기준.
# 가격 조정은 본 파일 수정 + 재배포로 반영.
module CreditPackages
  PACKAGES = [
    { key: "trial",   name: "체험팩",   credits: 10,  bonus: 0,   price_won: 1_900 },
    { key: "starter", name: "스타터",   credits: 30,  bonus: 0,   price_won: 4_900 },
    { key: "regular", name: "레귤러",   credits: 70,  bonus: 10,  price_won: 9_900 },
    { key: "value",   name: "밸류",     credits: 150, bonus: 30,  price_won: 19_900 },
    { key: "big",     name: "빅팩",     credits: 350, bonus: 100, price_won: 39_900 }
  ].freeze

  KEYS = PACKAGES.map { |p| p[:key] }.freeze

  def self.find(key)
    PACKAGES.find { |p| p[:key] == key.to_s }
  end

  def self.total_credits_for(key)
    p = find(key)
    return 0 unless p
    p[:credits] + p[:bonus]
  end

  def self.price_for(key)
    find(key)&.dig(:price_won) || 0
  end
end
