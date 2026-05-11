import { Controller } from "@hotwired/stimulus"

// 브라우저 Web Push 구독 토글 UI.
// data:
//   data-push-subscription-vapid-public-key-value: 서버 VAPID 공개키 (Base64URL)
// targets:
//   button         — 토글 버튼 (텍스트가 상태에 따라 바뀜)
//   unsupportedMsg — 미지원 환경에서 보여줄 안내
export default class extends Controller {
  static targets = ["button", "unsupportedMsg"]
  static values  = { vapidPublicKey: String }

  async connect() {
    if (!this.supported) {
      this.buttonTarget.hidden = true
      if (this.hasUnsupportedMsgTarget) this.unsupportedMsgTarget.hidden = false
      return
    }
    await this.refreshButton()
  }

  async toggle() {
    if (!this.supported) return
    this.buttonTarget.disabled = true
    try {
      const existing = await this.currentSubscription()
      if (existing) {
        await this.unsubscribe(existing)
      } else {
        await this.subscribe()
      }
    } catch (err) {
      console.error("[push] toggle failed", err)
      alert("알림 설정에 실패했어요. 브라우저/OS 알림 권한을 확인해주세요.")
    } finally {
      this.buttonTarget.disabled = false
      await this.refreshButton()
    }
  }

  // --- internal -------------------------------------------------------------

  get supported() {
    return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window
  }

  async registration() {
    return await navigator.serviceWorker.register("/service_worker.js")
  }

  async currentSubscription() {
    const reg = await this.registration()
    return await reg.pushManager.getSubscription()
  }

  async subscribe() {
    const permission = await Notification.requestPermission()
    if (permission !== "granted") throw new Error("permission denied")

    const reg = await this.registration()
    const sub = await reg.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.urlBase64ToUint8Array(this.vapidPublicKeyValue),
    })

    const keys = sub.toJSON().keys || {}
    await this.postJSON("/push_subscriptions", {
      push_subscription: {
        endpoint:   sub.endpoint,
        p256dh_key: keys.p256dh,
        auth_key:   keys.auth,
      },
    })
  }

  async unsubscribe(sub) {
    await sub.unsubscribe()
    await this.postJSON("/push_subscriptions/unsubscribe", { endpoint: sub.endpoint }, "DELETE")
  }

  async refreshButton() {
    const sub = await this.currentSubscription()
    if (sub) {
      this.buttonTarget.textContent = "브라우저 알림 끄기"
      this.buttonTarget.dataset.state = "subscribed"
    } else {
      this.buttonTarget.textContent = "브라우저 알림 받기"
      this.buttonTarget.dataset.state = "unsubscribed"
    }
  }

  async postJSON(url, body, method = "POST") {
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    const res = await fetch(url, {
      method,
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": csrf,
      },
      body: JSON.stringify(body),
    })
    if (!res.ok) throw new Error(`${method} ${url} → ${res.status}`)
  }

  // Web Push API가 요구하는 형식: Uint8Array (raw byte). 서버는 URL-safe Base64로 보냄.
  urlBase64ToUint8Array(base64) {
    const padding = "=".repeat((4 - base64.length % 4) % 4)
    const normalized = (base64 + padding).replace(/-/g, "+").replace(/_/g, "/")
    const raw = atob(normalized)
    const out = new Uint8Array(raw.length)
    for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i)
    return out
  }
}
