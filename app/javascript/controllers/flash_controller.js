import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-dismiss flash messages after 3 seconds
    this._timeout = setTimeout(() => this.remove(), 3000)
  }

  remove() {
    clearTimeout(this._timeout)
    this.element.remove()
  }

  disconnect() {
    clearTimeout(this._timeout)
  }
}
