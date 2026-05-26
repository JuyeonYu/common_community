# PortOne V2 셋업 가이드 (dev/prod 공통)

## 1. 콘솔 작업 — admin.portone.io

### 채널 추가
- 좌측 **연동 관리 → 채널 관리** → "채널 추가"
- **본인인증**: 다날 (휴대폰) — 50원/건 권장. 또는 KCP/KG이니시스 통합.
- **결제**: 운영 계약 전이면 KG이니시스/토스/나이스 **테스트 모드** 채널.
- 각 채널 생성 후 **Channel Key** 복사.

### V2 API Secret
- **상점 → 통합 정보 → V2 API Secret 발급**
- 생성 직후 1회만 표시. 분실 시 재발급.

### 웹훅 (I-4 시점)
- **연동 관리 → 웹훅** → URL `https://blackticket.messageopen.com/webhooks/portone`
- 이벤트: `Transaction.Paid` / `Transaction.Failed` / `Transaction.Cancelled` / `Transaction.VirtualAccountIssued`
- 등록 후 **Webhook Secret** 복사.

## 2. credentials 셋업

`bin/rails credentials:edit`로 다음 키 추가:

```yaml
portone:
  store_id: "store-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  channel_key_identity: "channel-key-xxxx-본인인증"
  channel_key_payment: "channel-key-xxxx-결제"
  api_secret: "..."            # 서버 전용
  webhook_secret: "..."        # 서버 전용 (I-4 후)
```

ENV 폴백도 가능 (`PORTONE_STORE_ID` 등) — `app/lib/port_one.rb` 참고.

## 3. 코드 통합 위치

| 단계 | 파일 |
|---|---|
| credentials/ENV 로드 | `app/lib/port_one.rb` |
| 클라이언트 노출 (meta + SDK) | `app/views/layouts/application.html.erb` |
| 본인인증 컨트롤러 | `app/controllers/identity_verifications_controller.rb` (I-2) |
| 결제 카드 분기 | `app/controllers/credit_purchases_controller.rb` (I-3) |
| 웹훅 | `app/controllers/webhooks/portone_controller.rb` (I-4) |

## 4. 도메인 변경 영향

- `User#ci/di/identity_verified_at` 컬럼 (Phase I-1 마이그레이션). CI unique.
- `CreditPurchase#paid_via`(enum) / `external_payment_id` / `paid_at` (Phase I-1 마이그레이션).
- 무통장입금 흐름은 그대로 유지(`paid_via: :bank_transfer`).

## 5. dev 테스트

- 테스트 채널은 PortOne 공용 ID로 0원 테스트 가능.
- 결제: 카드번호 `4242 4242 4242 4242` (KG이니시스 테스트 카드 사양 따름).
- 본인인증: 다날 테스트 모드는 모든 입력값 통과(SMS 없이 즉시 success).
