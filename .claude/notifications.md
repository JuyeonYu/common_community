# 알림 시스템 청사진

Jiindo의 알림 시스템 현재 구현과 향후 확장 계획. 작업 시 이 문서를 참고.

---

## 현재 구현 (Phase 7, MVP)

### 데이터 흐름
```
[댓글/답글/좋아요 발생]
        ↓
[after_create_commit 콜백]
        ↓
[Notification 레코드 DB 저장]
        ↓
[사용자가 페이지 로드/이동 시 헤더 뱃지 갱신]
        ↓
[/notifications 방문 시 자동 읽음 처리]
```

### 핵심 모델
- `Notification` (recipient_id, actor_id, action, 다형성 notifiable, read_at)
- `Comment#after_create_commit` → 글/부모 댓글 작성자에게
- `Like#after_create_commit` → 좋아요 받은 콘텐츠 작성자에게
- 자기 액션은 `return` (자기 글에 자기가 댓글/좋아요 → 알림 X)

### 액션 종류 (`Notification::ACTIONS`)
- `commented_on_post` — 내 글에 댓글
- `replied_to_comment` — 내 댓글에 답글
- `liked_post` — 내 글에 좋아요
- `liked_comment` — 내 댓글에 좋아요

새 액션 추가 시:
1. `Notification::ACTIONS`에 키 추가
2. `Notification#message`에 한글 문구 매핑
3. `Notification#link_path`가 새 notifiable 타입을 다룰 수 있는지 확인
4. 트리거 모델에 `after_create_commit` 콜백

### 전달 방식
**Pull only (현재)**: 사용자가 페이지 새로고침/이동 시 헤더 뱃지가 갱신됨. 실시간 푸시는 아래 확장 단계 참고.

---

## 향후 확장 1: 실시간 in-app (Phase 9 예정)

**Solid Cable + Turbo Stream broadcast** 사용. 퍼스트파티이므로 의존성 추가 없음.

### 추가 작업
1. `app/channels/notifications_channel.rb` — 사용자별 채널 구독
2. `Notification.after_create_commit` → `broadcast_prepend_to [recipient, :notifications]`
3. 헤더 뱃지를 Turbo Frame으로 감싸서 stream 수신 가능하게 변경
4. 알림 페이지 목록도 stream으로 prepend

### 기대 효과
- 페이지 새로고침 없이 실시간 알림 도착
- 헤더 뱃지 카운트 즉시 갱신

---

## 향후 확장 2: 브라우저 푸시 (Web Push API)

브라우저가 닫혀있을 때도 OS 레벨 알림 표시. 서비스 워커 + VAPID + Push API.

### 필요한 작업

1. **VAPID 키 페어 생성** (한 번)
   ```ruby
   # bin/rails runner
   require "webpush"
   WebPush.generate_key.to_h  # public_key, private_key
   ```
   결과를 `Rails.application.credentials.vapid`에 저장.

2. **gem 추가 검토 (사용자 승인 필요)**
   - `web-push` gem — Rails 퍼스트파티 없음. Web Push 프로토콜 처리에 필수
   - 또는 직접 구현 (RFC 8030, ECDH 암호화 — 추천하지 않음)

3. **DB 추가**: `push_subscriptions` 테이블
   - user_id, endpoint, p256dh_key, auth_key
   - 한 사용자가 여러 디바이스 가능 → 다중 row 허용

4. **JavaScript 측**
   - `app/javascript/push.js` — 권한 요청 + Service Worker 등록 + 서버에 subscription 전송
   - `public/service_worker.js` — push 이벤트 수신, `self.registration.showNotification()`

5. **서버 측 발송**
   - `Notification` 생성 후 → `Solid Queue` 잡으로 web-push 전송 (recipient의 모든 push_subscriptions에)
   - 401/410 응답 시 해당 subscription 자동 삭제

6. **사용자 설정 UI**
   - 프로필에 "브라우저 알림 받기" 토글
   - 권한 거부/철회 케이스 처리

### 보안/운영 주의
- VAPID 키 유출되면 다른 서버가 같은 사용자에게 푸시 가능 → credentials 관리
- Apple Safari는 별도 권한 모델, iOS Safari는 PWA 설치된 경우만 지원

---

## 향후 확장 3: 모바일 푸시 (iOS/Android 네이티브 앱)

Hotwire Native 앱이 설치된 사용자에게 OS 푸시 알림 전송.

### 아키텍처
```
[Notification 생성]
        ↓
[Solid Queue 잡]
        ↓
[APNs (iOS) / FCM (Android)]
        ↓
[디바이스 푸시 표시]
        ↓
[탭하면 앱이 deep link로 해당 글 이동]
```

### 필요한 작업

1. **DB 추가**: `device_tokens` 테이블
   - user_id, platform (`apns`/`fcm`), token, environment (`sandbox`/`production`)
   - 한 사용자 다중 디바이스

2. **서비스 키**
   - **iOS**: Apple Developer 계정에서 APNs Auth Key (.p8) 발급 → credentials에 저장
   - **Android**: Firebase 프로젝트 → FCM 서비스 계정 JSON → credentials에 저장

3. **gem 추가 검토 (사용자 승인 필요)**
   - **iOS**: `apnotic` 또는 `houston` (APNs HTTP/2 클라이언트). 퍼스트파티 없음
   - **Android**: `googleauth` + 직접 FCM HTTP v1 호출. 별도 SDK 사용 시 추가 검토
   - 또는 통합 서비스(OneSignal 등) 사용 — 외부 의존성 큼, 추천 신중

4. **네이티브 앱 측 (별도 저장소 작업)**
   - **iOS**: `UNUserNotificationCenter` 권한 요청 → APNs 토큰 획득 → 서버에 등록
   - **Android**: FCM SDK로 토큰 획득 → 서버에 등록
   - **Hotwire Native bridge**: 토큰 등록/푸시 수신 시 네이티브 ↔ 웹 통신
     - bridge component 정의 (Swift/Kotlin + JS) → 별도 도입 합의 필요

5. **서버 측 발송**
   - `Notification` 생성 후 잡 큐에 등록 → 사용자의 모든 device_tokens로 발송
   - 토큰 만료/무효 응답 시 해당 row 삭제
   - 본문은 `Notification#message`, deep link는 `link_path`

6. **Path Configuration 갱신**
   - `public/configurations/ios_v1.json`, `android_v1.json`에 알림 deep link 매핑
   - 알림 탭 → 앱이 해당 URL을 native push context로 표시

### 보안/운영 주의
- APNs Auth Key는 1개 키로 모든 앱 푸시 가능 → 누출 시 모든 사용자에게 메시지 발송 위험
- FCM 서비스 계정 JSON도 동일
- 서버 키는 절대 클라이언트 코드/저장소에 두지 말 것 (반드시 credentials/ENV)

---

## 확장 시 공통 고려사항

### 사용자 알림 환경설정
- 알림 종류별 ON/OFF (댓글/좋아요/멘션 등)
- 채널별 ON/OFF (in-app / 이메일 / 브라우저 푸시 / 모바일 푸시)
- 모델: `users` 테이블에 `notification_preferences` jsonb 컬럼 또는 별도 `notification_preferences` 테이블

### 발송 비동기화
- 모든 외부 푸시는 **Solid Queue 잡**으로 처리 (동기 발송 금지)
- 잡 안에서 retry/재시도 정책 명시

### 합치기 (Aggregation)
- 짧은 시간에 같은 콘텐츠에 여러 좋아요 → 한 알림으로 합치기 (e.g. "A님 외 5명이 좋아요")
- MVP에선 X. 사용자 피드백 기반으로 도입 결정

---

## 작업 시작 시 체크리스트 (확장 단계)

브라우저/모바일 푸시 작업을 시작할 때:

1. [ ] 사용자에게 새 gem 승인 받기 (`web-push`, `apnotic` 등)
2. [ ] credentials에 키/시크릿 등록 (사용자가 직접 발급)
3. [ ] DB 마이그레이션 (subscriptions / device_tokens)
4. [ ] 발송 로직 구현 + Solid Queue 잡으로 비동기화
5. [ ] 사용자 설정 UI (권한/구독 ON/OFF)
6. [ ] 토큰/구독 무효화 처리
7. [ ] 테스트 (mock APNs/FCM 응답)
