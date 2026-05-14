import { Controller } from "@hotwired/stimulus"

// @닉네임 자동완성. 일반 textarea 와 <trix-editor> 둘 다 지원.
//
// 컨테이너에 data-controller="mention-autocomplete",
// 입력 요소에 data-mention-autocomplete-target="input"
//   + data-action="input->mention-autocomplete#onInput keydown->mention-autocomplete#onKeydown",
// 후보 팝업 요소에 data-mention-autocomplete-target="popup" 을 단다.
export default class extends Controller {
  static targets = ["input", "popup"]

  connect() {
    this.suggestions = []
    this.activeIndex = -1
    this.abortController = null
    this.hide()
  }

  disconnect() {
    if (this.abortController) this.abortController.abort()
  }

  async onInput() {
    const ctx = this.getMentionContext()
    if (!ctx) { this.hide(); return }

    if (this.abortController) this.abortController.abort()
    this.abortController = new AbortController()

    try {
      const res = await fetch(`/users/search?q=${encodeURIComponent(ctx.query)}`, {
        signal: this.abortController.signal,
        headers: { "Accept": "application/json" }
      })
      if (!res.ok) { this.hide(); return }
      this.suggestions = await res.json()
      this.activeIndex = this.suggestions.length > 0 ? 0 : -1
      this.render()
    } catch (e) {
      if (e.name !== "AbortError") this.hide()
    }
  }

  onKeydown(event) {
    if (this.popupTarget.hidden || this.suggestions.length === 0) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.activeIndex = (this.activeIndex + 1) % this.suggestions.length
        this.render()
        break
      case "ArrowUp":
        event.preventDefault()
        this.activeIndex = (this.activeIndex - 1 + this.suggestions.length) % this.suggestions.length
        this.render()
        break
      case "Enter":
      case "Tab":
        if (this.activeIndex >= 0) {
          event.preventDefault()
          this.select(this.suggestions[this.activeIndex])
        }
        break
      case "Escape":
        event.preventDefault()
        this.hide()
        break
    }
  }

  selectByClick(event) {
    event.preventDefault()
    const idx = parseInt(event.currentTarget.dataset.index, 10)
    this.select(this.suggestions[idx])
  }

  // 캐럿 직전의 @prefix 추출. 없으면 null.
  // anchor = '@' 위치, end = 캐럿 위치. select 시 [anchor, end] 구간을 치환.
  getMentionContext() {
    const el = this.inputTarget
    const mentionRe = /@([\p{L}\p{N}_]{0,20})$/u

    if (el.tagName === "TRIX-EDITOR") {
      const editor = el.editor
      if (!editor) return null
      const range = editor.getSelectedRange()
      const pos = range[0]
      const text = editor.getDocument().toString().substring(0, pos)
      const match = text.match(mentionRe)
      if (!match) return null
      return { query: match[1], anchor: pos - match[0].length, end: pos, isTrix: true }
    } else {
      const pos = el.selectionStart
      const text = el.value.substring(0, pos)
      const match = text.match(mentionRe)
      if (!match) return null
      return { query: match[1], anchor: pos - match[0].length, end: pos, isTrix: false }
    }
  }

  select(user) {
    const ctx = this.getMentionContext()
    if (!ctx) { this.hide(); return }
    const replacement = `@${user.nickname} `
    const el = this.inputTarget

    if (ctx.isTrix) {
      el.editor.setSelectedRange([ctx.anchor, ctx.end])
      el.editor.insertString(replacement)
    } else {
      const before = el.value.substring(0, ctx.anchor)
      const after  = el.value.substring(ctx.end)
      el.value = before + replacement + after
      const newPos = before.length + replacement.length
      el.setSelectionRange(newPos, newPos)
      el.focus()
    }
    this.hide()
  }

  render() {
    if (this.suggestions.length === 0) { this.hide(); return }
    this.popupTarget.hidden = false
    this.popupTarget.innerHTML = this.suggestions.map((u, i) => `
      <button type="button"
              data-action="mousedown->mention-autocomplete#selectByClick"
              data-index="${i}"
              class="block w-full text-left px-3 py-1.5 text-sm hover:bg-blue-50 ${i === this.activeIndex ? "bg-blue-50" : ""}">
        @${this.escape(u.nickname)}
      </button>
    `).join("")
  }

  hide() {
    if (this.hasPopupTarget) {
      this.popupTarget.hidden = true
      this.popupTarget.innerHTML = ""
    }
    this.suggestions = []
    this.activeIndex = -1
  }

  escape(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
