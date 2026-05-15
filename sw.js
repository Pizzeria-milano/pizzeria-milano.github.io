/* Service Worker für Pizzeria Milano
   Empfängt Web-Push-Nachrichten für die Verwaltung – funktioniert auch,
   wenn Tab/Browser geschlossen oder das Display gesperrt ist. */

const SW_VERSION = 'pizzeria-milano-sw-v1';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('push', (event) => {
  let data = {};
  if (event.data) {
    try { data = event.data.json(); }
    catch { data = { title: 'Pizzeria Milano', body: event.data.text() }; }
  }

  const title = data.title || 'Neue Bestellung';
  const options = {
    body: data.body || 'Es ist eine neue Bestellung eingegangen.',
    icon: 'pizzeria-milano-icon-512.png',
    badge: 'favicon-32x32.png',
    tag: data.tag || 'pizzeria-order',
    renotify: true,
    requireInteraction: true,
    vibrate: [300, 120, 300, 120, 500],
    data: { order_id: data.order_id || null, ts: Date.now() }
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil((async () => {
    const scopeUrl = new URL(self.registration.scope);
    const all = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });

    for (const client of all) {
      try {
        const u = new URL(client.url);
        if (u.origin === scopeUrl.origin) {
          await client.focus();
          client.postMessage({ type: 'open-orders', order_id: event.notification.data?.order_id || null });
          return;
        }
      } catch { /* skip */ }
    }
    await self.clients.openWindow(scopeUrl.href);
  })());
});
