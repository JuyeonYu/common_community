require "test_helper"
require "yaml"
require "fugit"

# config/recurring.yml의 schedule이 fugit으로 파싱 가능한지 검증.
#
# 2026-05-13 502 인시던트 회귀 방지:
#   recurring.yml의 production 블록은 production 환경 부팅 시점에만 로드되므로
#   dev/test에서 검증되지 않은 채 운영으로 흘러간다. invalid schedule이 들어가면
#   Solid Queue가 종료되고 SOLID_QUEUE_IN_PUMA=true 모드에선 Puma까지 종료
#   → 컨테이너 Restarting 루프 → kamal-proxy 502.
#
# 이 테스트가 통과해야 운영 부팅이 안전.
class RecurringYmlTest < ActiveSupport::TestCase
  test "production 블록의 모든 schedule이 fugit cron으로 환산 가능해야 함" do
    yaml = YAML.load_file(Rails.root.join("config/recurring.yml")) || {}
    tasks = yaml["production"] || {}

    assert tasks.any?, "production 블록이 비어 있다 — recurring.yml 확인 필요"

    # 핵심: `Fugit.parse_cronish`는 cron으로 환산 가능한 schedule만 통과시킨다.
    # `(Asia/Seoul)` 같은 timezone 표기는 단일 시점(EoTime)으로만 파싱되어 nil 반환 —
    # 인시던트(2026-05-13)에서 Solid Queue가 거절했던 정확한 그 케이스.
    invalid = tasks.filter_map do |name, config|
      schedule = config.is_a?(Hash) ? config["schedule"] : nil
      next if schedule.blank?
      cron = Fugit.parse_cronish(schedule) rescue nil
      cron.is_a?(Fugit::Cron) ? nil : "#{name}: #{schedule.inspect}"
    end

    assert_empty invalid,
      "cron으로 환산 안 되는 schedule 발견 — 운영 배포 시 Solid Queue/Puma 종료 위험.\n" \
      "안전한 형식 예시는 config/recurring.yml 상단 주석 참고.\n" \
      "위반:\n  #{invalid.join("\n  ")}"
  end
end
