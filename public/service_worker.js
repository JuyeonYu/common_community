// Web Push 수신 → OS 알림 표시
// 서버(WebPushJob)가 보내는 payload 스키마: { title, body, icon, url, tag }
self.addEventListener("push", (event) => {
  if (!event.data) return;

  let payload;
  try {
    payload = event.data.json();
  } catch (_) {
    payload = { title: "Jiindo", body: event.data.text() };
  }

  const options = {
    body: payload.body,
    icon: payload.icon || "/icon.png",
    badge: "/icon.png",
    data: { url: payload.url || "/" },
    tag: payload.tag,
  };

  event.waitUntil(
    self.registration.showNotification(payload.title || "Jiindo", options)
  );
});

// 알림 클릭 → 같은 URL의 탭이 열려 있으면 그 탭으로 포커스, 없으면 새 탭 열기.
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const targetUrl = (event.notification.data && event.notification.data.url) || "/";

  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        try {
          const url = new URL(client.url);
          if (url.pathname === new URL(targetUrl, self.location.origin).pathname && "focus" in client) {
            return client.focus();
          }
        } catch (_) { /* ignore */ }
      }
      return self.clients.openWindow(targetUrl);
    })
  );
});
