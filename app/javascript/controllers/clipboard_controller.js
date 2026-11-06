import { Controller } from "@hotwired/stimulus"

// Copies the source field's text. If the browser blocks clipboard access,
// selects the text instead so it can be copied by hand.
export default class extends Controller {
  static targets = ["source", "button", "status"]

  async copy() {
    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
      this.announce("Copied", "Link copied.")
    } catch {
      this.select()
      this.announce("Selected", "Link selected. Use your device's Copy to copy it.")
    }
  }

  select() {
    this.sourceTarget.focus()
    this.sourceTarget.select()
  }

  announce(buttonText, message) {
    this.original ??= this.buttonTarget.textContent
    this.buttonTarget.textContent = buttonText
    if (this.hasStatusTarget) this.statusTarget.textContent = message

    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.buttonTarget.textContent = this.original
      if (this.hasStatusTarget) this.statusTarget.textContent = ""
    }, 2000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
