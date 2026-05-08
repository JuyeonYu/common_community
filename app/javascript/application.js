// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"

// 코드블록 비활성: Trix의 code 인라인 속성 제거 → 단축키(Cmd+E)도 비활성화
addEventListener("trix-before-initialize", () => {
  delete Trix.config.textAttributes.code
}, { once: true })
