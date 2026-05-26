import { Controller } from "@hotwired/stimulus"

// PortOne V2 본인인증 진입 컨트롤러.
// "본인인증 시작" 버튼 클릭 → PortOne.requestIdentityVerification → 성공 시 hidden form 제출.
export default class extends Controller {
  static targets = ["form", "button", "error"]
  static values  = {
    storeId: String,
    channelKey: String,
    identityVerificationId: String
  }

  async start(event) {
    event.preventDefault()
    if (!window.PortOne) {
      this.showError("결제 SDK를 불러오는 중입니다. 잠시 후 다시 시도해주세요.")
      return
    }
    this.buttonTarget.disabled = true
    try {
      const result = await window.PortOne.requestIdentityVerification({
        storeId: this.storeIdValue,
        channelKey: this.channelKeyValue,
        identityVerificationId: this.identityVerificationIdValue
      })
      if (result?.code) {
        this.showError(`본인인증 실패: ${result.message || result.code}`)
        this.buttonTarget.disabled = false
        return
      }
      // 성공 — hidden form 제출. 서버에서 PortOne REST로 검증.
      this.formTarget.requestSubmit()
    } catch (err) {
      this.showError(`오류: ${err?.message || err}`)
      this.buttonTarget.disabled = false
    }
  }

  showError(msg) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = msg
      this.errorTarget.hidden = false
    }
  }
}
