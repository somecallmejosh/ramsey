import { Controller } from "@hotwired/stimulus"

// Says how many photos were picked and flags any over the size limit
// before upload. The server enforces the same limit.
export default class extends Controller {
  static targets = ["input", "status"]
  static values = { maxBytes: Number }

  update() {
    const files = Array.from(this.inputTarget.files)
    const tooBig = files.filter((file) => file.size > this.maxBytesValue)

    if (files.length === 0) {
      this.statusTarget.textContent = ""
    } else if (tooBig.length > 0) {
      const names = tooBig.map((file) => file.name).join(", ")
      this.statusTarget.textContent = `Too large (over 3.75 MB): ${names}. Please pick smaller photos.`
    } else {
      this.statusTarget.textContent = `${files.length} ${files.length === 1 ? "photo" : "photos"} selected`
    }

    this.statusTarget.classList.toggle("text-claret", tooBig.length > 0)
    this.inputTarget.setCustomValidity(tooBig.length > 0 ? "Each photo must be 3.75 MB or smaller." : "")
  }
}
