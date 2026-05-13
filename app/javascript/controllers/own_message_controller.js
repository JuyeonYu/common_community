import { Controller } from "@hotwired/stimulus"

// 채팅 메시지 partial은 양쪽 사용자에게 같은 HTML로 broadcast된다.
// 본인 메시지(보낸이 == 현재 사용자)는 클라이언트에서 우측 정렬 + 파란 버블로 강조.
// 현재 사용자 ID는 layout의 <meta name="current-user-id">에서 읽는다.
export default class extends Controller {
  static values = { senderId: Number }

  connect() {
    const me = parseInt(document.querySelector('meta[name="current-user-id"]')?.content || "0")
    if (me && me === this.senderIdValue) {
      this.element.classList.remove("justify-start")
      this.element.classList.add("justify-end")
      const bubble = this.element.querySelector(".message-bubble")
      if (bubble) {
        bubble.classList.remove("bg-white", "border", "border-gray-200", "text-gray-900")
        bubble.classList.add("bg-blue-600", "text-white")
      }
    }
  }
}
