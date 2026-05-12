import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
      const original = this.element.textContent
      this.element.textContent = "복사됨"
      setTimeout(() => { this.element.textContent = original }, 1500)
    } catch (err) {
      alert("복사에 실패했어요. 직접 URL을 복사해주세요.")
    }
  }
}
