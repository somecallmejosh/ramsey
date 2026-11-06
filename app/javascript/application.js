import "@hotwired/turbo-rails"
import "controllers"
import "chartkick"
import "Chart.bundle"

// Installable app + offline screen + push notifications.
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker", { scope: "/" })
    .catch((error) => console.warn("Service worker registration failed", error))
}

// After each Turbo Drive navigation, move focus to main content so
// keyboard/screen reader users land at the top of the new page.
document.addEventListener("turbo:load", () => {
  const main = document.getElementById("main-content")
  if (main) main.focus()
})

// Phones keep the app suspended for days. When someone comes back to it,
// refresh so balances include what the rest of the household has logged.
const STALE_AFTER_MS = 60 * 1000
let hiddenAt = null

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "hidden") {
    hiddenAt = Date.now()
    return
  }
  const wasAwayLongEnough = hiddenAt && Date.now() - hiddenAt > STALE_AFTER_MS
  const isMidTask = document.querySelector("dialog[open]") || document.activeElement?.matches("input, textarea, select")
  hiddenAt = null
  if (wasAwayLongEnough && !isMidTask) window.Turbo?.visit(window.location.href, { action: "replace" })
})
