// Clempo service worker: offline fallback + household push notifications.
// Pages are never cached (balances must be live); only the offline screen is.
const CACHE_NAME = "clempo-v2"
const OFFLINE_URL = "/offline.html"
const OFFLINE_ASSETS = [OFFLINE_URL, "/icon.svg"]

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(OFFLINE_ASSETS))
      .then(() => self.skipWaiting())
  )
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  )
})

// Page loads go to the network; if there is no network, show the offline screen.
self.addEventListener("fetch", (event) => {
  if (event.request.mode !== "navigate") return

  event.respondWith(
    fetch(event.request).catch(() => caches.match(OFFLINE_URL))
  )
})

self.addEventListener("push", (event) => {
  let data = {}
  try {
    data = event.data ? event.data.json() : {}
  } catch {
    data = { body: event.data?.text() }
  }

  event.waitUntil(
    self.registration.showNotification(data.title || "Clempo", {
      body: data.body,
      icon: data.icon || "/web-app-manifest-192x192.png",
      badge: data.badge || "/notification-badge.png",
      data: { url: data.url || "/" },
    })
  )
})

// Open the page the notification is about, reusing an open Clempo window.
self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const url = new URL(event.notification.data?.url || "/", self.location.origin).href

  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((windows) => {
      const open = windows.find((client) => client.url.startsWith(self.location.origin))
      if (open) return open.navigate(url).then((client) => (client || open).focus())
      return self.clients.openWindow(url)
    })
  )
})
