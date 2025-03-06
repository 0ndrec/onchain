const CACHE_NAME = "pwa-cache-v3";
const ASSETS = [
    "/",
    "/index.html",
    "/styles.css",
    "/script.js",
    "/manifest.json",
    "/icons/icon-192.png",
    "/icons/icon-512.png"
];

// 📌 Установка Service Worker и кеширование ресурсов
self.addEventListener("install", event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => cache.addAll(ASSETS))
            .then(() => self.skipWaiting()) // Активируем SW сразу
            .catch(err => console.warn("Ошибка кеширования:", err))
    );
});

// 📌 Активация нового SW и очистка старого кеша
self.addEventListener("activate", event => {
    event.waitUntil(
        caches.keys().then(keys => {
            return Promise.all(
                keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))
            );
        }).then(() => self.clients.claim()) // Немедленно активируем новый SW
    );
});

// 📌 Перехват запросов — сначала берем из кеша, потом из сети
self.addEventListener("fetch", event => {
    event.respondWith(
        caches.match(event.request)
            .then(response => response || fetch(event.request))
            .catch(() => new Response("Ошибка соединения", { status: 503, statusText: "Service Unavailable" }))
    );
});
