import { Controller } from "@hotwired/stimulus"

// Auto-dismissing notice. Pauses while the pointer or focus is on it so
// nobody loses an Undo button while reaching for it.
export default class extends Controller {
  static values = { timeout: { type: Number, default: 3000 } }

  connect() {
    this.start()
    this.element.addEventListener("pointerenter", this.pause)
    this.element.addEventListener("focusin", this.pause)
    this.element.addEventListener("pointerleave", this.start)
    this.element.addEventListener("focusout", this.start)
  }

  start = () => {
    clearTimeout(this._timeout)
    this._timeout = setTimeout(() => this.remove(), this.timeoutValue)
  }

  pause = () => clearTimeout(this._timeout)

  remove() {
    clearTimeout(this._timeout)
    this.element.remove()
  }

  disconnect() {
    clearTimeout(this._timeout)
  }
}
