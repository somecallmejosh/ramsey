import { Controller } from "@hotwired/stimulus"

// Asks once per device to turn on household notifications.
// - Not asked yet: show the "ask" card.
// - Already allowed: quietly make sure this device's subscription is on file.
// - iPhone/iPad Safari outside the installed app: Apple only allows web push
//   from a Home Screen app, so explain how to add it instead.
// - Opted out in Settings: never ask. Settings can still turn this device on
//   by dispatching a "push:enable" event on window.
const SNOOZE_KEY = "pushSnoozedUntil"
const SNOOZE_MS = 14 * 24 * 60 * 60 * 1000

export default class extends Controller {
  static targets = ["ask", "install"]
  static values = { publicKey: String, optedIn: { type: Boolean, default: true } }

  connect() {
    if (!("serviceWorker" in navigator) || !this.publicKeyValue || !this.optedInValue) return

    if (this.#canPush) {
      if (Notification.permission === "granted") this.#subscribe()
      else if (Notification.permission === "default" && !this.#snoozed) this.#show(this.askTarget)
    } else if (this.#isAppleMobile && !this.#isInstalled && !this.#snoozed) {
      this.#show(this.installTarget)
    }
  }

  async enable() {
    this.#hide()
    if (!this.#canPush) return
    if (await Notification.requestPermission() === "granted") await this.#subscribe()
  }

  dismiss() {
    try { localStorage.setItem(SNOOZE_KEY, String(Date.now() + SNOOZE_MS)) } catch {}
    this.#hide()
  }

  async #subscribe() {
    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.getSubscription() ||
      await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.#urlBase64ToUint8Array(this.publicKeyValue)
      })

    await fetch("/push_subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
      },
      body: JSON.stringify({ subscription: subscription.toJSON() })
    })
  }

  #show(target) {
    target.hidden = false
    this.element.hidden = false
  }

  #hide() {
    this.element.hidden = true
  }

  get #canPush() {
    return "Notification" in window && "PushManager" in window
  }

  get #snoozed() {
    try { return Number(localStorage.getItem(SNOOZE_KEY) || 0) > Date.now() } catch { return false }
  }

  get #isAppleMobile() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent) ||
      (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
  }

  get #isInstalled() {
    return navigator.standalone === true || window.matchMedia("(display-mode: standalone)").matches
  }

  #urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = window.atob(base64)
    return Uint8Array.from(rawData, (char) => char.charCodeAt(0))
  }
}
