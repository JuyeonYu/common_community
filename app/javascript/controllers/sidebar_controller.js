import { Controller } from "@hotwired/stimulus"

// 모바일 사이드바 drawer.
// 햄버거 버튼 클릭 → drawer 열림. 백드롭 클릭/× 클릭 → 닫힘.
export default class extends Controller {
  static targets = ["drawer", "backdrop"]

  open() {
    this.drawerTarget.classList.remove("-translate-x-full")
    this.backdropTarget.hidden = false
    document.body.style.overflow = "hidden"
  }

  close() {
    this.drawerTarget.classList.add("-translate-x-full")
    this.backdropTarget.hidden = true
    document.body.style.overflow = ""
  }
}
