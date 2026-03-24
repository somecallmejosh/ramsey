const CACHE_NAME = "ramsey-v1"
const OFFLINE_URL = "/offline"

// Cache the app shell on install
self.addEventListener("install", (event) => {
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  event.waitUntil(clients.claim())
})

// Push notification handler (Phase 7)
self.addEventListener("push", async (event) => {
  const { title, body, icon } = await event.data.json()
  event.waitUntil(
    self.registration.showNotification(title, {
      body,
      icon: icon || "/icon.png",
      badge: "/icon.png",
      data: { url: "/" },
    })
  )
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  event.waitUntil(
    clients.matchAll({ type: "window" }).then((clientList) => {
      for (const client of clientList) {
        if ("focus" in client) return client.focus()
      }
      if (clients.openWindow) return clients.openWindow("/")
    })
  )
})
