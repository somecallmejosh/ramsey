import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
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
