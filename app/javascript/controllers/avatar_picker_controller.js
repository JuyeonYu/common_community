import { Controller } from "@hotwired/stimulus"

// 프로필 사진 입력: hidden file input + 원형 미리보기 + "사진 변경" 버튼.
// 사용자가 파일을 선택하면 즉시 FileReader로 미리보기를 갱신한다.
export default class extends Controller {
  static targets = ["input", "preview"]

  open() {
    this.inputTarget.click()
  }

  changed() {
    const file = this.inputTarget.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewTarget.classList.remove("hidden")
      const placeholder = this.element.querySelector("[data-avatar-picker-target='placeholder']")
      if (placeholder) placeholder.classList.add("hidden")
    }
    reader.readAsDataURL(file)
  }
}
