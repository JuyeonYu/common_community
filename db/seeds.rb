# 개발 환경 전용 시드 데이터.
# admin 사용자 1개 + 본인 이메일 SeedEmail 화이트리스트.
# dev에서 Google OAuth로 가입 시 SeedEmail 일치하면 admin 권한이 자동 적용된다.

if Rails.env.development?
  User.find_or_create_by!(email_address: "admin@example.com") do |user|
    user.name = "관리자"
    user.admin = true
    user.seed = true
    user.invitation_accepted_at = Time.current
  end

  puts "[seeds] 개발용 admin 사용자 준비됨: admin@example.com (Google OAuth 또는 콘솔로 진입)"
end
