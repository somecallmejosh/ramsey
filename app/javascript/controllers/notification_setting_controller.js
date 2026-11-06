import { Controller } from "@hotwired/stimulus"

// Settings → Notifications. The on/off switch is saved per person by the form;
// this controller explains what *this device* can do, and asks the browser for
// permission when turning on (the request has to happen inside the tap).
export default class extends Controller {
  static targets = ["device", "setup"]
  static values = { enabled: Boolean }

  connect() {
    this.#render()
  }

  // "Turn on" button: runs on click, before the form submits.
  turnOn() {
    this.#requestPush()
  }

  // "Set up this device" button: already opted in, this device isn't yet.
  setUp() {
    this.#requestPush()
    this.setupTarget.hidden = true
  }

  #requestPush() {
    window.dispatchEvent(new CustomEvent("push:enable"))
  }

  #render() {
    const canPush = "serviceWorker" in navigator && "Notification" in window && "PushManager" in window
    const isAppleMobile = /iphone|ipad|ipod/i.test(navigator.userAgent) ||
      (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)

    let note = null
    if (!canPush) {
      note = isAppleMobile
        ? "On iPhone, notifications only work from the Home Screen app. Add Clempo to your Home Screen, then open it from there."
        : "This browser can't show notifications."
    } else if (this.enabledValue && Notification.permission === "denied") {
      note = "Notifications are blocked for Clempo on this device. Allow them in your browser or phone settings."
    } else if (this.enabledValue && Notification.permission === "default" && this.hasSetupTarget) {
      this.setupTarget.hidden = false
    }

    if (note && this.hasDeviceTarget) {
      this.deviceTarget.textContent = note
      this.deviceTarget.hidden = false
    }
  }
}
