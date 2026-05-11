# 개발 환경 전용 시드 데이터.
# Google 자격증명이 없어도 이메일/비밀번호 로그인으로 동작 확인이 가능하도록 admin 계정 1개를 만든다.
# `bin/rails db:seed` 또는 `bin/rails db:setup`으로 실행.

# 자유 게시판은 마이그레이션에서 시드되지만, 누락된 경우(예: schema.rb로 부트스트랩) 보완.
Board.find_or_create_by!(slug: "free") do |b|
  b.name = "자유"
  b.position = 0
  b.allowed_prefixes = []
  b.write_permission = :everyone
end

if Rails.env.development?
  User.find_or_create_by!(email_address: "admin@example.com") do |user|
    user.password = "password"
    user.password_confirmation = "password"
    user.name = "관리자"
    user.admin = true
  end

  puts "[seeds] 개발용 admin 계정 준비됨: admin@example.com / password"
end

puts "[seeds] 자유 게시판 준비됨"
