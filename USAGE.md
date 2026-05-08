# 사용 가이드

이 저장소(`common_community`, 코드명 Jiindo)는 **여러 커뮤니티 서비스를 빠르게 시작하기 위한 Rails 8 베이스 템플릿**입니다. Google 로그인, 게시판(글/댓글/대댓글/태그), 검색, 좋아요, 신고/모더레이션, 알림(실시간), 프로필, 모바일(Hotwire Native) 지원이 기본 포함.

---

## 시나리오별 가이드

상황에 맞는 섹션부터 보세요.

### 시나리오 A. 처음 이 저장소 받아서 로컬 실행
→ [§1. 처음 셋업 (이 repo 자체)](#1-처음-셋업-이-repo-자체)

### 시나리오 B. 이 repo를 템플릿 삼아 새 커뮤니티 만들기
→ [§2. 새 커뮤니티 시작하기 (Template fork)](#2-새-커뮤니티-시작하기-template-fork)

### 시나리오 C. 이미 만든 커뮤니티에서 기능 추가/수정 작업
→ [§3. 일상 개발 흐름](#3-일상-개발-흐름)

### 시나리오 D. 원본 repo 보안패치/공통 개선을 fork에 가져오기
→ [§4. upstream 패치 받아오기](#4-upstream-패치-받아오기)

---

## 1. 처음 셋업 (이 repo 자체)

처음 코드를 받은 사람이 로컬 실행까지 가는 길.

```bash
# 1) 클론
git clone https://github.com/JuyeonYu/common_community.git
cd common_community

# 2) Ruby 설치 (rbenv 사용 가정)
rbenv install 4.0.1   # .ruby-version에 명시됨

# 3) PostgreSQL 17 (macOS Homebrew)
brew install postgresql@17
brew services start postgresql@17
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"  # 필요 시 ~/.zshrc에 추가

# 4) 의존성 + DB
bundle install
bin/rails db:create db:migrate db:seed

# 5) Google OAuth (선택, 로그인 테스트하려면 필요)
#    자세한 절차: README.md 의 "Google OAuth 자격증명 설정" 섹션
EDITOR="vim" bin/rails credentials:edit
# google: { client_id: ..., client_secret: ... }

# 6) 서버 기동
bin/dev
```

브라우저: http://localhost:3000

**Google credentials 등록 안 해도** "관리자/개발자 로그인"으로 접속 가능:
- 이메일: `admin@example.com` / 비밀번호: `password` (db:seed가 만들어줌)

---

## 2. 새 커뮤니티 시작하기 (Template fork)

이 저장소가 GitHub Template으로 표시되어 있어야 함 (Settings → Template repository 체크).

### 절차 요약

1. https://github.com/JuyeonYu/common_community → 우상단 **Use this template** → **Create a new repository**
2. 새 repo 이름/설명 입력 (예: `running-community`)
3. clone → 저장소에 포함된 **`TEMPLATE_SETUP.md`** 따라 진행
   - 앱 이름/모듈명 변경 (Jiindo → 새 이름)
   - credentials/master.key 재발급
   - Google OAuth 새 클라이언트 발급
   - DB 셋업
   - 색상/도메인 어휘 등 차별화
4. 셋업 끝나면 `TEMPLATE_SETUP.md` 파일 삭제

> 자세한 단계와 명령어: [`TEMPLATE_SETUP.md`](TEMPLATE_SETUP.md)

---

## 3. 일상 개발 흐름

새 기능 / 버그 수정 / 디자인 변경 작업 시 표준 절차.

### 3.1 브랜치 만들고 작업

```bash
git checkout main
git pull
git checkout -b feature/<짧은-설명>     # 예: feature/board-prefix
```

### 3.2 코드 작성

- 컨트롤러는 얇게, 모델은 두껍게 (`.claude/CLAUDE.md` 참조)
- gem 추가가 필요해 보이면 → 먼저 Rails 퍼스트파티 확인 → 정말 필요하면 코드 작업 전에 합의
- 새 모델/마이그레이션:
  ```bash
  bin/rails generate migration CreateXxx field:type ...
  # 마이그레이션 파일 즉시 열어서 인덱스/제약조건 보강
  bin/rails db:migrate
  ```

### 3.3 테스트 작성 + 실행

```bash
bin/rails test                           # 전체
bin/rails test test/models/post_test.rb  # 특정 파일
bin/rails test test/models/post_test.rb:42  # 특정 라인
```

새 기능에는 **반드시 테스트 동반** (모델/컨트롤러/시스템 적절히).

### 3.4 품질 검사

```bash
bin/rubocop          # 스타일
bin/rubocop -a       # 자동 수정 (안전한 것만)
bin/brakeman --quiet # 보안 정적 분석
bin/bundle-audit     # 의존성 취약점
```

CI에서 자동 실행되지만 push 전에 한 번 돌리면 빠른 피드백.

### 3.5 커밋 + 푸시 + PR

```bash
git add <files>
git commit -m "한글 커밋 메시지 (왜 변경했는지)"
git push -u origin feature/<짧은-설명>
```

GitHub에서 PR 생성 → 리뷰 → 머지.

> **main 직접 push 금지**. main 보호 규칙 설정해두면 강제됨.

---

## 4. upstream 패치 받아오기

원본 `common_community`에 보안 패치/공통 개선이 추가됐을 때 fork로 가져오는 법.

```bash
# (최초 1회) upstream remote 등록
git remote add upstream https://github.com/JuyeonYu/common_community.git
git fetch upstream

# 원하는 커밋만 cherry-pick
git checkout -b chore/upstream-patch
git log upstream/main --oneline | head -10  # 어느 커밋?
git cherry-pick <commit-hash>

# 충돌 나면 해결 후
git add <conflict-files>
git cherry-pick --continue

git push -u origin chore/upstream-patch
# GitHub에서 PR
```

**전체 머지(`git merge upstream/main`)는 비추천**. fork가 분기되면 충돌 폭주.

---

## 자주 쓰는 명령어 치트시트

```bash
# 개발 서버 (Rails + Tailwind watcher 같이 기동)
bin/dev

# 콘솔
bin/rails console

# DB
bin/rails db:create db:migrate db:seed
bin/rails db:reset            # ⚠️ 모든 데이터 날림 (개발용만)
bin/rails db:rollback:primary # 최근 마이그레이션 1개 되돌리기

# 테스트
bin/rails test
bin/rails test:system         # System Test (Capybara, 느림)

# 품질
bin/rubocop
bin/brakeman --quiet
bin/bundle-audit

# Credentials
EDITOR="vim" bin/rails credentials:edit
# 또는 EDITOR="code --wait"

# 마이그레이션 새로 만들기
bin/rails generate migration AddXxxToYyy field:type
```

---

## 디렉토리 안내

```
app/
  controllers/
    application_controller.rb     # turbo_native_app? 헬퍼, Pagy::Backend
    concerns/authentication.rb     # 로그인/admin 인가
    posts_controller.rb            # 글
    comments_controller.rb         # 댓글 (Turbo Stream)
    notifications_controller.rb    # 알림 (자동 읽음)
    admin/                         # 관리자 페이지 (require_admin)
    posts/likes_controller.rb      # 글 좋아요 (다형성)
    comments/likes_controller.rb   # 댓글 좋아요
  models/
    user.rb                        # 인증 + 프로필 + 아바타
    post.rb                        # Likeable, Reportable, PgSearch
    comment.rb                     # 2단계 깊이 강제
    like.rb / report.rb / notification.rb  # 다형성
    concerns/likeable.rb / reportable.rb   # 공통 패턴
  views/
    layouts/_header.html.erb       # 헤더 (네이티브 앱에선 숨김)
    posts/                         # 피드/상세/폼
    comments/                      # 댓글 구역, Turbo Stream
    notifications/                 # 알림 페이지 + Turbo Stream 구독
    admin/reports/                 # 관리자 신고 처리
    shared/_notification_badge     # 헤더 뱃지 (broadcast 대상)
    *.html+native.erb              # Hotwire Native 전용 변형
  channels/application_cable/
    connection.rb                  # ActionCable 인증 (signed cookie)
  helpers/application_helper.rb    # avatar_image, like_url_for, pagy
  javascript/application.js        # Turbo + Stimulus + Trix(코드블록 비활성)
  assets/stylesheets/              # Trix CSS, application.css
  assets/tailwind/application.css  # Tailwind v4 entry

config/
  application.rb                   # ko 로케일, Asia/Seoul, autoload 등
  routes.rb                        # 라우트 한눈에 보기
  database.yml                     # multi-DB (primary/cache/queue/cable)
  initializers/omniauth.rb         # Google OAuth provider
  locales/ko.yml                   # 한글 날짜/시간 포맷

db/
  migrate/                         # 마이그레이션 11개 (페이즈별)
  schema.rb                        # 자동 생성 (커밋 대상)
  seeds.rb                         # 개발용 admin 계정

public/configurations/             # Hotwire Native Path Configuration
  ios_v1.json
  android_v1.json

test/
  models/, controllers/, integration/, channels/
  fixtures/                        # 픽스처 (FactoryBot 미사용)

.claude/                           # AI(Claude/Cursor) 작업용 컨텍스트
  CLAUDE.md                        # 5대 코딩 원칙 + 스택 + 규칙
  notifications.md                 # 푸시 확장 청사진

# 루트 문서
README.md                          # 빠른 셋업 + Google OAuth 절차
TEMPLATE_SETUP.md                  # fork 시 셋업 체크리스트
USAGE.md                           # 이 파일
```

---

## 문서 인덱스

| 파일 | 언제 보나 |
|---|---|
| **README.md** | 처음 받았을 때 빠른 실행 |
| **USAGE.md** (이 파일) | "어떻게 쓰지?" 헷갈릴 때 시나리오별 안내 |
| **TEMPLATE_SETUP.md** | 새 커뮤니티 만들 때 단계별 체크 |
| **.claude/CLAUDE.md** | 코드 작성/리뷰 원칙 (AI 도구가 같이 읽음) |
| **.claude/notifications.md** | 브라우저/모바일 푸시 도입할 때 |

---

## 자주 만나는 문제

### "Migrations are pending" 인데 마이그레이션은 다 적용됨
→ Bootstrap 캐시 stale. `bin/dev` 재시작 + `rm -rf tmp/cache/bootsnap`.

### `bundle install`이 `pg` gem 빌드에서 실패
→ PostgreSQL 미설치. `brew install postgresql@17` + `export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"`.

### Google 로그인 시 `redirect_uri_mismatch`
→ Google Cloud Console의 **승인된 리디렉션 URI**가 정확히 `http://localhost:3000/auth/google_oauth2/callback` (개발용)인지 확인. `localhost`/`127.0.0.1` 일치 필요.

### 테스트 실행하면 멈춤 / crash report
→ macOS + PG fork 충돌. test_helper.rb의 `parallelize(workers: 1)`이 적용됐는지 확인 (이미 기본). 더 빠르게 돌리려면 `PARALLEL_WORKERS=2` 환경변수.

### Trix 에디터가 안 보임
→ `app/javascript/application.js`의 `import "trix"`(default export 없음)이 정상인지. `addEventListener("trix-before-initialize", ...)`로 설정.

### 알림이 실시간으로 안 옴
→ `bin/dev`가 Action Cable + Solid Cable 동작 중인지. `config/cable.yml` 확인. 로그에서 "[ActionCable] Subscribed" 메시지 확인.

---

## 다음 단계 (이 베이스를 넘어선 작업)

각 커뮤니티에서 자주 추가되는 기능:

- **게시판 분류**: `Board` 모델 추가 → `Post.belongs_to :board`
- **말머리 / Prefix**: 간단하면 enum, 자유로우면 별도 컬럼/모델
- **별점 / 추천 시스템**: Like를 score 칼럼으로 확장 또는 Vote 모델
- **이미지 첨부**: Action Text + Active Storage (이미 셋업됨, UI만 추가)
- **이메일 알림**: Action Mailer + Solid Queue 잡 (인프라 필요)
- **브라우저/모바일 푸시**: [`.claude/notifications.md`](.claude/notifications.md) 청사진 참조

---

## 도움 받기

- 코드 작성 도움: AI(Claude Code/Cursor)에 `.claude/CLAUDE.md`가 자동으로 컨텍스트로 들어감 → 5대 원칙대로 진행
- 보안 의심 가는 PR: `bin/brakeman` + 인증/인가 변경 시 사용자 검증
- 운영 장애 (배포 후): Kamal 로그 확인 (`bin/kamal app logs`)
