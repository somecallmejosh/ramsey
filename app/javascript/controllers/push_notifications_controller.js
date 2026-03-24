import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (
      !("Notification" in window) ||
      Notification.permission !== "default" ||
      localStorage.getItem("pushDismissed")
    ) {
      this.element.remove()
    }
  }

  async enable() {
    const permission = await Notification.requestPermission()
    if (permission === "granted") {
      await this.#subscribe()
    }
    this.element.remove()
  }

  dismiss() {
    localStorage.setItem("pushDismissed", "1")
    this.element.remove()
  }

  async #subscribe() {
    const registration = await navigator.serviceWorker.ready
    const publicKey = document.querySelector("meta[name='vapid-public-key']")?.content
    if (!publicKey) return

    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.#urlBase64ToUint8Array(publicKey)
    })

    await fetch("/push_subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({ subscription: subscription.toJSON() })
    })
  }

  #urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = window.atob(base64)
    const output = new Uint8Array(rawData.length)
    for (let i = 0; i < rawData.length; ++i) output[i] = rawData.charCodeAt(i)
    return output
  }
}
