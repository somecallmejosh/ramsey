import { Controller } from "@hotwired/stimulus"

// Busy text for forms Turbo doesn't submit (data-turbo="false"). Reads the
// same data-turbo-submits-with attribute Turbo uses, so markup stays alike.
export default class extends Controller {
  connect() {
    window.addEventListener("pageshow", this.reset)
  }

  disconnect() {
    window.removeEventListener("pageshow", this.reset)
  }

  busy(event) {
    const button = event.submitter || this.element.querySelector("[type=submit]")
    const text = button?.dataset.turboSubmitsWith
    if (!text) return

    this.button = button
    this.original = this.label(button)
    this.setLabel(button, text)
    // Disable after the browser has collected the form data.
    setTimeout(() => { button.disabled = true })
  }

  // Coming back via the Back button restores the page from cache; undo the busy state.
  reset = () => {
    if (!this.button) return
    this.setLabel(this.button, this.original)
    this.button.disabled = false
    this.button = null
  }

  label(button) {
    return button.tagName === "INPUT" ? button.value : button.textContent
  }

  setLabel(button, text) {
    if (button.tagName === "INPUT") button.value = text
    else button.textContent = text
  }
}
