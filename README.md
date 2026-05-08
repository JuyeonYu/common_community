# Jiindo

Rails 8 기반 웹 커뮤니티 서비스. 웹 + 모바일(iOS/Android) 동시 배포 목표.

작업 지침은 [`.claude/CLAUDE.md`](.claude/CLAUDE.md) 참조.

---

## 기술 스택

- **Ruby** 4.0.1 / **Rails** 8.1
- **PostgreSQL**
- **Hotwire** (Turbo + Stimulus) + **Hotwire Native** (iOS/Android)
- **Tailwind CSS**
- **Solid Queue / Solid Cache / Solid Cable** (Redis 미사용)
- **Action Text** (코드블록 비활성)
- **Minitest + Capybara**
- 검색: `pg_search` / 페이지네이션: `pagy`
- 배포: **Kamal 2**

---

## 시스템 요구사항

- Ruby 4.0.1 (`.ruby-version` 참조)
- PostgreSQL 17 이상
- Node.js (Tailwind 빌드용)

### 처음 셋업

```bash
# rbenv 사용 시
rbenv install 4.0.1

# PostgreSQL (macOS)
brew install postgresql@17
brew services start postgresql@17
```

---

## 개발 셋업

```bash
# 의존성 설치
bundle install

# DB 생성 + 마이그레이션
bin/rails db:create db:migrate

# 개발 서버 (Rails + Tailwind watcher)
bin/dev
```

기본 주소: http://localhost:3000

---

## Google OAuth 자격증명 설정

Google 로그인을 사용하려면 OAuth 자격증명을 발급받아 Rails credentials에 등록해야 합니다.

### 1. Google Cloud Console에서 OAuth 클라이언트 생성

1. https://console.cloud.google.com/ 접속
2. 새 프로젝트 생성 (예: Jiindo)
3. **APIs & Services → OAuth consent screen** 설정 (앱 이름, 지원 이메일 등)
4. **APIs & Services → Credentials → Create credentials → OAuth client ID**
5. Application type: **Web application** 선택
6. **Authorized redirect URIs**에 추가:
   - 개발용: `http://localhost:3000/auth/google_oauth2/callback`
   - 운영용: `https://your-domain.com/auth/google_oauth2/callback`
7. 발급된 **Client ID**와 **Client Secret**을 메모

### 2. Rails credentials에 등록

```bash
EDITOR="vim" bin/rails credentials:edit
# 또는: EDITOR="code --wait" bin/rails credentials:edit
```

열린 YAML 파일에 추가:

```yaml
google:
  client_id: "발급받은 Client ID"
  client_secret: "발급받은 Client Secret"
```

저장 후 종료. `config/credentials.yml.enc`(암호화)는 git에 커밋, `config/master.key`는 절대 커밋하지 말 것 (`.gitignore`에 이미 포함).

### 3. 동작 확인

```bash
bin/dev
```

브라우저에서 http://localhost:3000 → 로그인 → "Google로 로그인" 버튼 클릭 → Google 동의 화면 → 로그인 완료.

---

## 자주 쓰는 명령어

```bash
# 테스트
bin/rails test                   # 단위/통합 테스트
bin/rails test:system            # System Test

# 품질 검사
bin/rubocop                      # 린트
bin/brakeman                     # 보안 스캔
bin/bundle-audit                 # 의존성 취약점

# 콘솔
bin/rails console
```

---

## 배포

Kamal 2로 배포한다. 자세한 배포 절차는 배포 시점에 별도 합의.

```bash
bin/kamal deploy
```

---

## 모바일 앱

iOS / Android 네이티브 앱은 **Hotwire Native**로 구현하며, **별도 저장소**에서 관리한다. 본 저장소는 서버(웹) 측만 다룬다.

네이티브 앱은 표준 Turbo 요청에 `Turbo Native iOS` / `Turbo Native Android` User-Agent를 붙이고, Rails는 `ApplicationController#turbo_native_app?` 헬퍼로 이를 감지해 뷰를 분기한다 (`*.html+native.erb` variant).

URL별 네이티브 표시 방식 정의: [`public/configurations/ios_v1.json`](public/configurations/ios_v1.json), [`public/configurations/android_v1.json`](public/configurations/android_v1.json).

---

## 디렉터리 안내

- `app/` — 애플리케이션 코드 (Rails 표준)
- `config/` — 설정 (`application.rb`, `database.yml`, `locales/ko.yml` 등)
- `public/configurations/` — Hotwire Native Path Configuration
- `.claude/CLAUDE.md` — Claude/AI 작업 지침
- `.kamal/` — 배포 설정
