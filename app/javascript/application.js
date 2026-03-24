import "@hotwired/turbo-rails"
import "controllers"
import "chartkick"
import "Chart.bundle"

// After each Turbo Drive navigation, move focus to main content so
// keyboard/screen reader users land at the top of the new page.
document.addEventListener("turbo:load", () => {
  const main = document.getElementById("main-content")
  if (main) main.focus()
})
