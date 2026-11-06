import { Controller } from "@hotwired/stimulus"

// Show/hide toggle for a password field. The button stays hidden until
// this connects, so it never appears without JavaScript to back it.
export default class extends Controller {
  static targets = ["input", "button", "text"]

  connect() {
    this.buttonTarget.hidden = false
  }

  toggle() {
    const showing = this.inputTarget.type === "text"
    this.inputTarget.type = showing ? "password" : "text"
    this.buttonTarget.setAttribute("aria-pressed", String(!showing))
    this.textTarget.textContent = showing ? "Show" : "Hide"
  }

  // Put the field back to hidden before the browser caches the page.
  disconnect() {
    this.inputTarget.type = "password"
  }
}
