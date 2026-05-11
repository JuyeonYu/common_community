import { Controller } from "@hotwired/stimulus"

// 글 작성/수정 폼에서 게시판 드롭다운이 바뀔 때
// 말머리 드롭다운의 옵션을 해당 게시판의 allowed_prefixes로 갱신.
export default class extends Controller {
  static values = { prefixes: Object }   // { "<board_id>": ["질문", "정보"], ... }
  static targets = [ "boardSelect", "prefixSelect" ]

  update() {
    const boardId = this.boardSelectTarget.value
    const prefixes = this.prefixesValue[boardId] || []
    const currentSelection = this.prefixSelectTarget.value

    this.prefixSelectTarget.innerHTML = ""

    const blankOption = document.createElement("option")
    blankOption.value = ""
    blankOption.textContent = "(선택 안 함)"
    this.prefixSelectTarget.appendChild(blankOption)

    prefixes.forEach(p => {
      const opt = document.createElement("option")
      opt.value = p
      opt.textContent = p
      if (p === currentSelection) opt.selected = true
      this.prefixSelectTarget.appendChild(opt)
    })

    // 말머리 옵션이 없는 게시판이면 select 자체 숨김
    this.prefixSelectTarget.parentElement.classList.toggle("hidden", prefixes.length === 0)
  }
}
