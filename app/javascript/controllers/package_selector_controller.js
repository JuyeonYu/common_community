import { Controller } from "@hotwired/stimulus"

// 크레딧 충전 페이지의 패키지 카드 선택 — 라디오 변경 시:
// - 카드 시각 강조
// - 입금 금액(amount) input들에 패키지 정가 자동 채움
// - 카드/무통장 hidden package_key input들에 선택 key 주입
export default class extends Controller {
  static targets = ["card", "radio", "amount", "packageKey", "selectedMark"]
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

    if (key && this.hasPricesValue) {
      const price = this.pricesValue[key]
      if (price && this.hasAmountTarget) {
        this.amountTargets.forEach((el) => {
          if (el.type === "number" || el.type === "text") el.value = price
        })
      }
      if (this.hasPackageKeyTarget) {
        this.packageKeyTargets.forEach((el) => { el.value = key })
      }
    }
  }
}
