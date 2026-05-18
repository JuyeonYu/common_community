import { Controller } from "@hotwired/stimulus"

// 채팅 메시지 partial은 양쪽 사용자에게 같은 HTML로 broadcast된다.
// 본인 메시지(보낸이 == 현재 사용자)는 클라이언트에서 우측 정렬 + accent 색 버블로 강조.
// 본인 전용 영역(.own-only)은 본인일 때만 노출.
// 현재 사용자 ID는 layout의 <meta name="current-user-id">에서 읽는다.
export default class extends Controller {
  static values = { senderId: Number }

  connect() {
    const me = parseInt(document.querySelector('meta[name="current-user-id"]')?.content || "0")
    const isOwn = me && me === this.senderIdValue
    if (isOwn) {
      this.element.classList.remove("justify-start")
      this.element.classList.add("justify-end")
      const bubble = this.element.querySelector(".message-bubble")
      if (bubble) {
        bubble.style.backgroundColor = "var(--color-accent)"
        bubble.style.color = "var(--color-accent-on)"
        bubble.style.borderColor = "transparent"
        // 본인 버블 내부의 약한 텍스트도 가독성 보정
        bubble.querySelectorAll("p, .own-only").forEach((el) => {
          el.style.color = "rgba(255,255,255,0.85)"
        })
      }
    } else {
      this.element.querySelectorAll(".own-only").forEach((el) => el.remove())
    }
  }
}
