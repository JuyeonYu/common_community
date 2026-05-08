# 새 커뮤니티 셋업 체크리스트

이 저장소(Jiindo)를 **GitHub Template**으로 fork해서 새 커뮤니티 서비스를 시작할 때 따라할 절차입니다.

> 셋업 완료 후 이 파일은 삭제하세요. (각 커뮤니티 repo에선 더 이상 쓸모 없음)

---

## 0. Template에서 새 repo 생성

1. https://github.com/JuyeonYu/common_community 접속
2. 우상단 **Use this template** → **Create a new repository**
3. 새 repo 이름/설명 입력 (예: `running-community`) → Create

생성된 repo를 로컬로 클론:
```bash
git clone https://github.com/JuyeonYu/<new-repo-name>.git
cd <new-repo-name>
```

---

## 1. 앱 이름/모듈명 변경

`Jiindo` → 새 이름(예: `Running`)로 변경:

| 파일 | 변경 전 | 변경 후 |
|---|---|---|
| `config/application.rb` | `module Jiindo` | `module Running` |
| `config/cable.yml` | `Jiindo_*` 채널명 | `Running_*` |
| `config/database.yml` | `jiindo_development` 등 | `running_development` 등 |
| `Procfile.dev` | (변경 불필요) | - |
| `app/views/layouts/application.html.erb` | `<title>... Jiindo` 등 | 새 이름 |
| `app/views/layouts/_header.html.erb` | `Jiindo` 로고 텍스트 | 새 이름 |
| `app/views/home/index.html.erb` (이미 제거됨) | - | - |
| `README.md` | 프로젝트 설명 | 새 커뮤니티 설명 |
| `Dockerfile`, `.kamal/secrets`, `config/deploy.yml` | 앱명 참조 | 새 이름 |

**일괄 변경 (주의해서 확인 후 실행):**
```bash
# macOS sed 기준 (gsed 권장)
grep -rl "Jiindo" --include="*.rb" --include="*.yml" --include="*.erb" . | xargs sed -i "" "s/Jiindo/Running/g"
grep -rl "jiindo" --include="*.rb" --include="*.yml" --include="*.erb" . | xargs sed -i "" "s/jiindo/running/g"
```
검토 → 의도치 않은 곳 수정됐는지 `git diff` 확인 → 커밋.

---

## 2. credentials 새로 발급

원본 repo의 `config/master.key`는 **이 fork에서 사용 금지**. 새로 만드세요.

```bash
# 기존 암호화 파일 삭제
rm config/credentials.yml.enc

# 새 credentials 생성 (master.key 자동 생성)
EDITOR="vim" bin/rails credentials:edit
# (편집기 열리면 그냥 :wq로 저장 종료 — Rails가 알아서 secret_key_base 생성)
```

`config/master.key`가 생성됐는지 확인하고, **절대 커밋 금지** (이미 .gitignore에 포함).

별도로 백업: 1Password / Vault / 팀 비밀저장소 등.

---

## 3. Google OAuth 자격증명 재발급

새 커뮤니티마다 별도 OAuth 클라이언트 필요.

1. https://console.cloud.google.com/ → 새 프로젝트 또는 기존 프로젝트
2. **OAuth 동의 화면** → 외부 → 앱 정보 입력
3. **사용자 인증 정보** → OAuth 클라이언트 ID 만들기 (웹 애플리케이션)
4. 승인된 리디렉션 URI:
   - 개발: `http://localhost:3000/auth/google_oauth2/callback`
   - 운영: `https://<your-domain>/auth/google_oauth2/callback`
5. 발급된 client_id / client_secret을 credentials에 등록:

```bash
EDITOR="vim" bin/rails credentials:edit
```
```yaml
google:
  client_id: <new client id>
  client_secret: <new client secret>
```

---

## 4. DB 셋업

```bash
bin/rails db:create db:migrate db:seed
```

`db:seed`는 dev용 admin 계정 생성 (`admin@example.com` / `password`). 운영 배포 전에 비밀번호 변경 필수.

---

## 5. 동작 확인

```bash
bin/rails test     # 모든 테스트 통과 확인 (139개)
bin/rubocop        # 린트
bin/brakeman --quiet  # 보안 스캔
bin/dev            # 서버 기동
```

http://localhost:3000 → 로그인 / 글쓰기 / 댓글 / 좋아요 / 검색 동작 확인.

---

## 6. 커뮤니티 차별화 (단계별 권장)

새 커뮤니티의 정체성을 만들기. 한 번에 다 하지 말고 **사용자 피드백 받으면서**:

| 항목 | 시기 | 작업 |
|---|---|---|
| 색상/로고 | 즉시 | Tailwind 색상 + favicon 교체 |
| 도메인 어휘 | 첫 사용자 받기 전 | "글" → "후기"/"질문"/"레시피" 등 |
| 게시판 분류 | 콘텐츠 쌓이기 시작할 때 | Board 모델 추가 → Post에 board_id |
| 말머리 (prefix) | 카테고리 필요해질 때 | Post에 prefix 컬럼 또는 Tag 활용 |
| 추가 메타데이터 | 도메인 특화 (별점/난이도/지역) | 마이그레이션 + 폼 필드 |

> Rails Way 유지: 새 컬럼/모델 → migration 추가, Service Object 남발 금지, 기존 Likeable/Reportable concern 재활용.

---

## 7. 배포 준비 (별도 합의)

- Kamal 2 설정 (`config/deploy.yml`) — 서버/도메인/registry 채우기
- DB 백업 정책
- 모니터링/로그 (Sentry 등은 별도 합의)
- 도메인 + HTTPS

---

## 운영 중 원본 repo 변경사항 가져오기

원본(common_community)에 보안 패치나 핵심 기능 개선이 들어왔을 때:

```bash
git remote add upstream https://github.com/JuyeonYu/common_community.git
git fetch upstream

# 원하는 커밋만 cherry-pick
git cherry-pick <commit-hash>

# 또는 patch 파일로
git format-patch -1 <commit-hash>
git apply <patch-file>
```

전체 머지(`git merge upstream/main`)는 fork가 분기되면 충돌 많아서 **권장 안 함**. cherry-pick으로 필요한 것만.
