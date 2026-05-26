import { Controller } from "@hotwired/stimulus"

// 크레딧 충전 페이지의 패키지 카드 선택 — 라디오 변경 시 카드 강조 + 입금 금액 자동 채움.
// 사용처: app/views/credit_purchases/new.html.erb
export default class extends Controller {
  static targets = ["card", "radio", "amount", "selectedMark"]
  static values  = { prices: Object }

  connect() {
    this.refresh()
  }

  onChange() {
    this.refresh()
  }

  refresh() {
    const selected = this.radioTargets.find((r) => r.checked)
    const key = selected?.value

    this.cardTargets.forEach((card) => {
      const isSelected = card.dataset.packageKey === key
      if (isSelected) {
        card.style.borderColor = "var(--color-accent)"
        card.style.boxShadow   = "0 0 0 2px var(--color-accent-soft)"
      } else {
        card.style.borderColor = ""
        card.style.boxShadow   = ""
      }
      const mark = card.querySelector('[data-package-selector-target="selectedMark"]')
      if (mark) mark.hidden = !isSelected
    })

    if (key && this.hasAmountTarget && this.hasPricesValue) {
      const price = this.pricesValue[key]
      if (price) this.amountTarget.value = price
    }
  }
}
