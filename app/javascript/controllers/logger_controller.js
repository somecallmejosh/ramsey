import { Controller } from "@hotwired/stimulus"

// Log a purchase in three taps: category → amount → Save.
// The sheet lives in the page (no fetch to open it) and uses an on-screen
// keypad so nobody waits for, or fights with, the phone keyboard.
export default class extends Controller {
  static targets = [
    "dialog", "form", "title", "historyLink", "display", "balance", "error",
    "amountField", "dateField", "datePicker", "dateInput", "note", "submit", "submitLabel"
  ]
  static values = { today: String, yesterday: String }

  static MAX_WHOLE_DIGITS = 6

  connect() {
    this.money = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" })
    this.dialogTarget.addEventListener("keydown", this.typed)
    this.dialogTarget.addEventListener("click", this.clickedBackdrop)
  }

  disconnect() {
    this.dialogTarget.removeEventListener("keydown", this.typed)
    this.dialogTarget.removeEventListener("click", this.clickedBackdrop)
  }

  // -- Opening / closing -------------------------------------------------

  open({ params: { url, name, remaining } }) {
    this.formTarget.action = url
    this.historyLinkTarget.href = url
    this.titleTarget.textContent = name
    this.envelopeName = name
    this.remaining = remaining === "" ? null : Number(remaining)
    this.reset()
    this.dialogTarget.showModal()
    // Focus the sheet itself: no ring on Cancel, and the phone keyboard stays
    // down because the on-screen keypad is the way in.
    this.dialogTarget.focus()
  }

  close() {
    this.dialogTarget.close()
  }

  clickedBackdrop = (event) => {
    if (event.target === this.dialogTarget) this.close()
  }

  reset() {
    this.entry = ""
    this.saving = false
    this.errorTarget.innerHTML = ""
    this.noteTarget.value = ""
    this.formTarget.querySelector('input[name="logger_when"][value="today"]').checked = true
    this.datePickerTarget.hidden = true
    this.dateInputTarget.value = ""
    this.dateFieldTarget.value = this.todayValue
    this.render()
  }

  // -- Amount entry ------------------------------------------------------

  press({ params: { key } }) {
    this.append(String(key))
  }

  backspace() {
    this.entry = this.entry.slice(0, -1)
    this.render()
  }

  typed = (event) => {
    if (event.target === this.noteTarget || event.target === this.dateInputTarget) return
    if (event.metaKey || event.ctrlKey || event.altKey) return

    if (/^[0-9.]$/.test(event.key)) {
      event.preventDefault()
      this.append(event.key)
    } else if (event.key === "Backspace") {
      event.preventDefault()
      this.backspace()
    } else if (event.key === "Enter" && this.amount > 0) {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
  }

  append(key) {
    let next = this.entry
    const [whole, cents] = next.split(".")

    if (key === ".") {
      if (next.includes(".")) return
      next = (next || "0") + "."
    } else if (cents !== undefined) {
      if (cents.length >= 2) return
      next += key
    } else {
      if (whole.length >= this.constructor.MAX_WHOLE_DIGITS) return
      next = whole === "0" ? key : next + key
    }

    this.entry = next
    this.render()
  }

  get amount() {
    return Number.parseFloat(this.entry) || 0
  }

  // -- Date --------------------------------------------------------------

  chooseDay(event) {
    const choice = event.target.value
    this.datePickerTarget.hidden = choice !== "earlier"

    if (choice === "today") this.dateFieldTarget.value = this.todayValue
    if (choice === "yesterday") this.dateFieldTarget.value = this.yesterdayValue
    if (choice === "earlier") {
      this.dateInputTarget.value ||= this.yesterdayValue
      this.dateFieldTarget.value = this.dateInputTarget.value
      this.dateInputTarget.focus()
    }
  }

  pickDate() {
    if (this.dateInputTarget.value) this.dateFieldTarget.value = this.dateInputTarget.value
  }

  // -- Rendering ---------------------------------------------------------

  render() {
    const amount = this.amount
    const hasAmount = amount > 0

    this.amountFieldTarget.value = hasAmount ? amount.toFixed(2) : ""
    this.displayTarget.textContent = this.formatEntry()
    this.displayTarget.classList.toggle("text-mute", !this.entry)
    this.displayTarget.classList.toggle("text-ink", !!this.entry)

    this.renderBalance(amount)

    if (!this.saving) {
      this.submitTarget.disabled = !hasAmount
      this.setSubmitLabel(hasAmount ? `Save ${this.money.format(amount)}` : "Enter an amount")
    }
  }

  setSubmitLabel(text) {
    this.submitLabelTarget.textContent = text
    this.submitTarget.setAttribute("aria-label", text)
  }

  // Show what's typed, as typed ("12." stays "12."), with thousands commas.
  formatEntry() {
    if (!this.entry) return "$0"
    const [whole, cents] = this.entry.split(".")
    const grouped = Number(whole || 0).toLocaleString("en-US")
    return cents === undefined ? `$${grouped}` : `$${grouped}.${cents}`
  }

  renderBalance(amount) {
    const el = this.balanceTarget
    el.classList.remove("text-claret")

    if (this.remaining === null) {
      el.textContent = "No budget set for this category"
      return
    }

    const after = this.remaining - amount
    if (amount <= 0) {
      el.textContent = this.remaining < 0
        ? `Already ${this.money.format(-this.remaining)} over budget`
        : `${this.money.format(this.remaining)} left`
    } else if (after < 0) {
      el.textContent = `This puts ${this.envelopeName} ${this.money.format(-after)} over`
      el.classList.add("text-claret")
    } else {
      el.textContent = `${this.money.format(after)} left after this`
    }
  }

  // -- Submitting --------------------------------------------------------

  submitting() {
    this.saving = true
    this.errorTarget.innerHTML = ""
    this.submitTarget.disabled = true
    this.setSubmitLabel("Saving…")
  }

  submitted(event) {
    this.saving = false
    const { success, fetchResponse } = event.detail

    if (success) {
      this.close()
      return
    }

    // A 422 response streams its own message into the error target.
    if (!fetchResponse) {
      this.errorTarget.innerHTML =
        '<p class="mb-1 text-[15px] text-claret">Couldn’t save. Check your connection and tap Save again.</p>'
    }
    this.render()
  }
}
