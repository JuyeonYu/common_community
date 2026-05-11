import { Controller } from "@hotwired/stimulus"

// Turbo Stream broadcast로 받은 메시지는 발송자 시점으로 렌더링되므로,
// 모든 클라이언트가 같은 HTML을 받음. 본인 메시지인지는 클라이언트에서 판단.
//
// 서버는 중립(왼쪽/흰색) 스타일로 렌더링하고, 본인 발송이면 이 컨트롤러가
// 오른쪽/파란 스타일로 전환. 회수 버튼/신고 링크 가시성도 여기서 결정.
export default class extends Controller {
  static values = {
    senderId: Number,
    createdAt: Number, // unix timestamp
  }
  static targets = [ "bubble", "footer", "recallButton", "reportLink" ]

  connect() {
    if (this.isMine()) {
      this.markAsMine()

      if (!this.canRecall()) {
        this.recallButtonTargets.forEach(el => el.remove())
      }

      this.reportLinkTargets.forEach(el => el.remove())
    } else {
      this.recallButtonTargets.forEach(el => el.remove())
    }
  }

  isMine() {
    const meta = document.querySelector('meta[name="current-user-id"]')
    if (!meta) return false
    const me = parseInt(meta.content, 10)
    return Number.isFinite(me) && me === this.senderIdValue
  }

  canRecall() {
    const elapsedSeconds = Date.now() / 1000 - this.createdAtValue
    return elapsedSeconds < 5 * 60
  }

  markAsMine() {
    this.element.classList.remove("justify-start")
    this.element.classList.add("justify-end")

    if (this.hasBubbleTarget) {
      this.bubbleTarget.classList.remove("bg-white", "text-gray-800", "border-gray-200")
      this.bubbleTarget.classList.add("bg-blue-600", "text-white", "border-blue-600")
    }

    if (this.hasFooterTarget) {
      this.footerTarget.classList.remove("text-gray-500")
      this.footerTarget.classList.add("text-blue-100")
    }

    this.recallButtonTargets.forEach(el => el.classList.remove("hidden"))
  }
}
