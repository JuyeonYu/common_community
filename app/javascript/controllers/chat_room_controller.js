import { Controller } from "@hotwired/stimulus"

// 대화방 페이지(conversations/show)에서 두 가지를 처리:
// 1) 새 메시지 도착 시 mark_read 자동 호출 (헤더 뱃지가 잘못 +1되는 것 방지)
// 2) 스크롤 UX:
//    - 사용자가 최하단을 보고 있으면 → 자동으로 새 메시지로 스크롤
//    - 위로 올라가 둘러보는 중이면 → 하단에 "↓ 새 메시지 N개" 버튼 표시
export default class extends Controller {
  static values = { conversationId: Number }
  static targets = [ "messagesList", "newMessageButton" ]

  connect() {
    this.wasAtBottom = true
    this.newCount = 0

    // 진입 시 최하단으로 스크롤 (instant — 첫 진입의 어색한 애니메이션 방지)
    this.scrollToBottom("instant")

    this.observer = new MutationObserver(this.onMutations.bind(this))
    this.observer.observe(this.messagesListTarget, { childList: true })

    this.boundOnScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.boundOnScroll, { passive: true })
  }

  disconnect() {
    this.observer?.disconnect()
    window.removeEventListener("scroll", this.boundOnScroll)
  }

  onMutations(mutations) {
    const newArticles = mutations
      .flatMap(m => Array.from(m.addedNodes))
      .filter(n => n.nodeType === Node.ELEMENT_NODE && n.tagName === "ARTICLE")

    if (newArticles.length === 0) return

    // 1) 다른 사용자가 보낸 메시지가 하나라도 있으면 mark_read 호출
    const meId = this.currentUserId()
    const fromOthers = newArticles.some(n => {
      const senderId = Number(n.dataset.ownMessageSenderIdValue)
      return Number.isFinite(senderId) && senderId !== meId
    })
    if (fromOthers) this.markRead()

    // 2) 스크롤 처리
    if (this.wasAtBottom) {
      this.scrollToBottom("smooth")
    } else {
      this.newCount += newArticles.length
      this.showNewMessageButton()
    }
  }

  onScroll() {
    this.wasAtBottom = this.isAtBottom()
    if (this.wasAtBottom) this.hideNewMessageButton()
  }

  jumpToBottom() {
    this.scrollToBottom("smooth")
    this.hideNewMessageButton()
  }

  // ─── private ───

  isAtBottom() {
    const tolerance = 80
    return window.scrollY + window.innerHeight >= document.documentElement.scrollHeight - tolerance
  }

  scrollToBottom(behavior = "smooth") {
    window.scrollTo({ top: document.documentElement.scrollHeight, behavior })
  }

  markRead() {
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    if (!csrf) return
    fetch(`/conversations/${this.conversationIdValue}/read`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": csrf,
        "Accept": "application/json"
      }
    }).catch(() => { /* 네트워크 오류는 무시 — 다음 페이지 로드 시 자연 정정 */ })
  }

  currentUserId() {
    const meta = document.querySelector('meta[name="current-user-id"]')
    return Number(meta?.content || 0)
  }

  showNewMessageButton() {
    if (!this.hasNewMessageButtonTarget) return
    this.newMessageButtonTarget.textContent = `↓ 새 메시지 ${this.newCount}개`
    this.newMessageButtonTarget.classList.remove("hidden")
  }

  hideNewMessageButton() {
    if (!this.hasNewMessageButtonTarget) return
    this.newCount = 0
    this.newMessageButtonTarget.classList.add("hidden")
  }
}
