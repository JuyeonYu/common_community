# 블랙티켓 작업 지침

블랙티켓(BlackTicket)은 Rails 8 기반의 **초대제 소개팅·구인구직 플랫폼**이다. 같이 일해본 사람만 초대할 수 있는 리퍼럴 + 추천인 연대책임(스코어 페널티) 구조가 핵심. 웹 + 모바일(iOS/Android) 동시 배포를 목표로 하며, 모바일은 **Hotwire Native**(37signals 퍼스트파티)로 단일 코드베이스를 유지한다.

상위 기획서: `doc/TalkFile_블랙티켓_상위기획서_v1.1.docx`.

작업자(사용자)는 Rails 입문자다. **결정의 근거를 짧게 설명하면서 진행한다.**

---

## 1. 5대 원칙

1. **Rails 8 / Ruby 4 기준**으로 작업한다.
2. **퍼스트파티 우선** — gem을 추가하기 전에 Rails / Hotwire / Solid 시리즈에 같은 기능이 있는지 먼저 확인한다.
3. **gem 추가는 사용자 승인제** — 퍼스트파티로 해결이 안 되는 경우에만, **사용자에게 이유를 설명하고 승인을 받은 뒤** 의존성을 추가한다. 무단 추가 금지.
4. **Rails Way 준수** — Thin Controller, Fat Model. Service Object / Form Object 등 새 레이어를 함부로 만들지 않는다. 과한 추상화 금지.
5. **테스트로 코드를 지킨다** — 새 기능과 버그 수정에는 테스트가 동반된다. 테스트 없이 머지하지 않는다.

---

## 2. 확정 기술 스택

| 영역 | 선택 | 비고 |
|---|---|---|
| Ruby | 4.0.1 | `.ruby-version` |
| Rails | 8.1.x | `config.load_defaults 8.1` |
| DB | PostgreSQL | `pg` gem |
| 캐시 | Solid Cache | DB 기반, Redis 미사용 |
| 백그라운드 잡 | Solid Queue | DB 기반, Sidekiq 미사용 |
| WebSocket | Solid Cable | DB 기반 |
| 인증 | Rails 8 내장 | `bin/rails g authentication`, Devise 미사용 |
| 프론트엔드(웹) | Hotwire (Turbo + Stimulus) | SPA 미사용 |
| **모바일 앱** | **Hotwire Native** | iOS/Android 네이티브 셸이 웹 화면을 감싸는 하이브리드 |
| CSS | Tailwind | `tailwindcss-rails` |
| 에셋 | Propshaft | Rails 8 기본 |
| 파일 업로드 | Active Storage + image_processing(libvips) | |
| 리치 텍스트 | Action Text + Trix | **코드블록 비활성** |
| 이메일 | Action Mailer | |
| 페이지네이션 | `pagy` gem | Rails 퍼스트파티 없음, 가장 가벼움 |
| 브라우저 푸시 | `web-push` gem | VAPID + Service Worker. RFC 8030 직접 구현 비현실적 |
| Rate limit | `ActionController::RateLimiting` | Rails 8 내장 |
| N+1 감지 | `assert_queries_count` | 테스트로 검증, Bullet 미사용 |
| 테스트 | Minitest + Capybara System Test | RSpec/FactoryBot 미사용 |
| 보안 스캔 | Brakeman + bundler-audit | CI에서 실행 |
| 린터 | rubocop-rails-omakase | |
| 배포 | Kamal 2 | |
| i18n | `:ko` 기본 | `Asia/Seoul` 타임존 |
| 언어 | 한글 | 커밋/PR/주석/에러 메시지 |

승인된 외부 gem: `pg`, `tailwindcss-rails`, `pagy`, `web-push`. 그 외는 추가 시 사용자 승인 필요.

---

## 3. 코딩 규칙

- **컨트롤러**: REST 액션만. 비즈니스 로직 금지. 10줄 내외 목표. 인증/인가는 `before_action`.
- **모델**: 검증 / 연관 / 스코프 / 콜백 / 도메인 메서드. 200~300줄 넘으면 **concern**으로 분리.
- **Service Object 사용 금지선**: 외부 API 호출, 멀티 모델 트랜잭션이 한 흐름에서 일어날 때만 허용. 그 외엔 모델/concern으로 처리한다.
- **뷰**: Hotwire 우선. Turbo Frames / Turbo Streams 활용. SPA 패턴 도입 금지.
- **모바일 분기**: 네이티브 앱 전용 동작이 필요하면 `turbo_native_app?` 헬퍼 + 뷰 variant(`*.html+native.erb`)로 분기. **별도 컨트롤러/엔드포인트 만들지 말 것.** 단일 코드베이스 유지.
- **마이그레이션**: 안전한 변경 우선. `change` 메서드 사용. 큰 테이블 변경은 사용자와 논의.
- **i18n**: 사용자 노출 문자열은 모두 `t(".key")`. 하드코딩 금지.
- **시간**: `Time.current` / `Date.current` 사용. `Time.now` 금지.
- **N+1**: `includes` / `preload` / `eager_load` 적극 사용. 의심스러운 곳은 테스트에서 `assert_queries_count`로 명시.
- **주석**: 기본은 안 쓴다. **왜**가 비자명할 때만 한 줄. 한국어로.
- **파일 명명**: Rails 컨벤션 준수 (`snake_case.rb`, 단/복수 규칙).

---

## 4. 테스트 규칙

- **Minitest** 사용. RSpec 미사용.
- **픽스처** 사용. FactoryBot 미사용 (퍼스트파티 우선).
- **모델 테스트**: 검증, 스코프, 도메인 메서드를 커버.
- **컨트롤러/통합 테스트**: 인증/인가, 응답 코드, 핵심 분기를 커버.
- **System Test (Capybara)**: 핵심 사용자 플로우 — 가입/로그인/글쓰기/댓글 등.
- **N+1 검증**: 핵심 인덱스/리스트 화면은 `assert_queries_count`로 쿼리 수를 명시.
- **테스트 없이 머지 금지.**

---

## 5. 보안 규칙

- **Strong Parameters** 필수. 모델에 `mass_assignment` 허용 금지.
- **SQL 인젝션 방지**: 문자열 보간 금지, 파라미터 바인딩 사용 (`where("name = ?", name)` 또는 `where(name: name)`).
- **XSS**: `raw` / `html_safe` 사용 시 사용자와 논의.
- **인증/인가** 변경 PR은 보안 리뷰 트리거.
- **Brakeman**과 **bundler-audit**는 CI에서 실행, 경고 발생 시 머지 금지.
- 비밀값은 `Rails.application.credentials` / 환경변수 사용. 코드에 직접 적지 않는다.

---

## 6. 모바일 (Hotwire Native) 가이드

- 네이티브 앱은 **웹 화면을 그대로 감싼다**. 새 화면이 필요하면 **웹 화면을 먼저 만든다**.
- 네이티브 앱은 요청에 `Turbo Native iOS` 또는 `Turbo Native Android` 같은 User-Agent를 붙여 보낸다. `ApplicationController`의 `turbo_native_app?` 헬퍼로 감지한다.
- 화면 분기:
  - 가벼운 분기 → `if turbo_native_app?` 또는 `turbo_native_app? ? ... : ...`
  - 큰 분기 → 뷰 variant: `index.html+native.erb` (네이티브 전용), `index.html.erb` (웹 기본)
- **Path Configuration JSON** 파일 (`public/configurations/ios_v1.json`, `public/configurations/android_v1.json`)은 네이티브 앱이 URL별로 어떤 표시 방식(modal, push 등)을 쓸지 정의한다. URL 경로 변경 시 네이티브 앱 호환성 주의.
- 네이티브 전용 UI(공유, 다이얼로그 등)는 **bridge component**(구 Strada)로 추후 합의 후 도입. 현재는 도입하지 않는다.
- **네이티브 앱 코드(Swift/Kotlin)는 별도 저장소**로 관리한다. 본 저장소엔 서버 측만.

---

## 7. 작업 흐름

### 새 기능을 만들 때

1. **퍼스트파티 확인** — Rails / Hotwire / Solid 시리즈로 가능한지 먼저 본다.
2. **퍼스트파티로 안 되면 사용자에게 보고** — "이런 이유로 X gem이 필요합니다"라고 설명하고 승인을 기다린다.
3. **Rails Way로 구현** — 컨트롤러 thin, 모델 fat, 추상화 최소.
4. **테스트 작성** — 모델/컨트롤러/필요시 System Test.
5. **모바일 영향 검토** — 새 화면이라면 네이티브 앱에서 어떻게 보일지 검토하고 필요시 variant 또는 Path Configuration 보완.

### gem 추가 판단

- **Rails 팀 공식**(예: `tailwindcss-rails`)이라도 이미 승인된 목록에 없으면 사용자 확인.
- 정말 단순한 유틸은 **직접 작성**(<30줄)이 의존성 추가보다 낫다.
- "유명한 gem"이라는 이유만으로는 부족하다. **왜 퍼스트파티로 안 되는가**가 답할 수 있어야 한다.

### 추상화 도입 판단

- "혹시 미래에 필요할까봐"는 **금지 사유**다.
- 같은 패턴이 **세 군데**에서 반복되고, 추출이 명확히 단순해질 때만 추출.
- Service Object를 만들고 싶을 땐 먼저 모델 메서드 / concern으로 처리 가능한지 본다.

### 커밋 / PR

- 메시지는 **한글**.
- 커밋은 가능하면 작게 분리.
- PR 본문에 "왜"를 적는다. "무엇"은 diff가 보여준다.

---

## 8. 도메인 (블랙티켓 — 진행 중)

상위 기획서: `doc/TalkFile_블랙티켓_상위기획서_v1.1.docx`.

피벗 후 도메인 핵심:
- **초대제 가입** (Invitation, 7일 1회 무료, 12시간 토큰, 추천인 코멘트)
- **휴대폰 본인인증** (외부 SDK 미정 — Phase B에서는 stub)
- **티켓 스코어** (10점, 0점 정지, 추천인 연대책임)
- **티켓 크레딧** (서비스 내 유료 화폐 — 결제 PG 미정)
- **레드티켓** (이성 매칭, 주간 기수)
- **골든티켓** (구인구직, 전자계약 + 채용 수수료 — 후속 Phase)

도입 시점/외부 의존성이 정해진 항목만 단계적으로 합류. Phase D 이후는 별도 plan.

---

## 9. CI / 배포

- `.github/workflows/`: rubocop, brakeman, bundler-audit, minitest, system test 자동 실행.
- 머지 조건: 모든 체크 통과 + 테스트 동반.
- 배포: Kamal 2. 배포 타겟 인프라는 배포 직전 합의.

---

## 10. 명령어 치트시트

```bash
# 개발 서버
bin/dev                          # Procfile.dev 실행 (Rails + Tailwind watcher)
bin/rails server                 # Rails만

# DB
bin/rails db:create db:migrate   # 초기 셋업
bin/rails db:reset               # 초기화

# 테스트
bin/rails test                   # 전체 (System Test 제외)
bin/rails test:system            # System Test
bin/rails test test/models/...   # 특정 파일

# 품질
bin/rubocop                      # 린트
bin/rubocop -a                   # 자동 수정
bin/brakeman                     # 보안 스캔
bin/bundle-audit                 # 의존성 취약점

# 콘솔
bin/rails console
```
