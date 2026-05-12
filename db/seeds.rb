# 개발 환경 전용 시드 데이터.
# Google 자격증명이 없어도 이메일/비밀번호 로그인으로 동작 확인이 가능하도록 admin 계정 1개를 만든다.
# 관리자는 seed=true로 두어 초대 코드 없이 활성 상태.

if Rails.env.development?
  User.find_or_create_by!(email_address: "admin@example.com") do |user|
    user.password = "password"
    user.password_confirmation = "password"
    user.name = "관리자"
    user.admin = true
    user.seed = true
    user.invitation_accepted_at = Time.current
  end

  puts "[seeds] 개발용 admin 계정 준비됨: admin@example.com / password"
end
