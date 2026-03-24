import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card"]

  connect() {
    this._focusableSelectors = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    this._previouslyFocused = null
  }

  open() {
    this.element.classList.remove("hidden")
    this._previouslyFocused = document.activeElement
    this._trapFocus()
  }

  close() {
    this.element.classList.add("hidden")
    if (this._previouslyFocused) {
      this._previouslyFocused.focus()
      this._previouslyFocused = null
    }
  }

  // Close on backdrop click (click on overlay, not card)
  clickOutside(event) {
    if (event.target === this.element) this.close()
  }

  _trapFocus() {
    const focusable = [...this.cardTarget.querySelectorAll(this._focusableSelectors)]
    if (focusable.length) focusable[0].focus()

    this.element.addEventListener("keydown", (e) => {
      if (e.key !== "Tab") return
      const first = focusable[0]
      const last  = focusable[focusable.length - 1]
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault(); last.focus()
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault(); first.focus()
      }
    })
  }
}
