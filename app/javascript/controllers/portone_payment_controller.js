import { Controller } from "@hotwired/stimulus"

// PortOne V2 결제(카드) 시작 컨트롤러.
// 패키지 선택 후 "카드 결제" 버튼 클릭 → PortOne.requestPayment → 성공 시 hidden form 제출.
export default class extends Controller {
  static targets = ["form", "button", "error", "packageInput", "paymentIdInput"]
  static values  = {
    storeId: String,
    channelKey: String,
    packages: Object // { key: { name, total_credits, price_won } }
  }

  async start(event) {
    event.preventDefault()
    if (!window.PortOne) {
      this.showError("결제 SDK를 불러오는 중입니다. 잠시 후 다시 시도해주세요.")
      return
    }
    const key = this.packageInputTarget.value
    const pkg = this.packagesValue[key]
    if (!pkg) {
      this.showError("패키지를 선택해주세요.")
      return
    }

    const paymentId = `payment-${crypto.randomUUID()}`
    this.paymentIdInputTarget.value = paymentId
    this.buttonTarget.disabled = true

    try {
      const result = await window.PortOne.requestPayment({
        storeId: this.storeIdValue,
        channelKey: this.channelKeyValue,
        paymentId: paymentId,
        orderName: `블랙티켓 ${pkg.name} (+${pkg.total_credits} 크레딧)`,
        totalAmount: pkg.price_won,
        currency: "KRW",
        payMethod: "CARD"
      })
      if (result?.code) {
        this.showError(`결제 실패: ${result.message || result.code}`)
        this.buttonTarget.disabled = false
        return
      }
      // 성공 — 서버에서 검증 + 충전.
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
