// Cally PWA Service Worker
const CACHE_NAME = 'cally-v1.0.0';
const STATIC_CACHE = 'cally-static-v1';
const DYNAMIC_CACHE = 'cally-dynamic-v1';

// Files to cache for offline functionality
const STATIC_ASSETS = [
  '/',
  '/chat',
  '/chat/history',
  '/settings',
  '/manifest.json',
  '/favicon.ico',
  '/apple-touch-icon.png',
  // Add your main CSS and JS files here
  '/assets/application.css',
  '/assets/application.js'
];

// Install event - cache static assets
self.addEventListener('install', event => {
  console.log('🔧 Cally Service Worker: Installing...');
  
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then(cache => {
        console.log('📦 Cally Service Worker: Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      })
      .then(() => {
        console.log('✅ Cally Service Worker: Installation complete');
        return self.skipWaiting();
      })
      .catch(error => {
        console.error('❌ Cally Service Worker: Installation failed', error);
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
  console.log('🚀 Cally Service Worker: Activating...');
  
  event.waitUntil(
    caches.keys()
      .then(cacheNames => {
        return Promise.all(
          cacheNames.map(cacheName => {
            if (cacheName !== STATIC_CACHE && cacheName !== DYNAMIC_CACHE) {
              console.log('🗑️ Cally Service Worker: Deleting old cache', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => {
        console.log('✅ Cally Service Worker: Activation complete');
        return self.clients.claim();
      })
  );
});

// Fetch event - serve from cache or network
self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }
  
  // Skip external requests (API calls, etc.)
  if (url.origin !== location.origin) {
    return;
  }
  
  event.respondWith(
    caches.match(request)
      .then(cachedResponse => {
        if (cachedResponse) {
          console.log('📱 Cally Service Worker: Serving from cache', request.url);
          return cachedResponse;
        }
        
        console.log('🌐 Cally Service Worker: Fetching from network', request.url);
        return fetch(request)
          .then(response => {
            // Don't cache non-successful responses
            if (!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }
            
            // Clone the response for caching
            const responseToCache = response.clone();
            
            // Cache dynamic content
            caches.open(DYNAMIC_CACHE)
              .then(cache => {
                cache.put(request, responseToCache);
              });
            
            return response;
          })
          .catch(error => {
            console.log('❌ Cally Service Worker: Network error', error);
            
            // Return offline page for navigation requests
            if (request.mode === 'navigate') {
              return caches.match('/') || new Response('Offline - Please check your connection');
            }
            
            throw error;
          });
      })
  );
});

// Handle background sync for chat messages (when available)
self.addEventListener('sync', event => {
  if (event.tag === 'background-sync') {
    console.log('🔄 Cally Service Worker: Background sync triggered');
    event.waitUntil(
      // Handle offline message queue here if needed
      Promise.resolve()
    );
  }
});

// Handle push notifications (for future features)
self.addEventListener('push', event => {
  if (event.data) {
    const data = event.data.json();
    const options = {
      body: data.body || 'Cally has a new message for you!',
      icon: '/icons/icon-192x192.png',
      badge: '/icons/icon-72x72.png',
      vibrate: [200, 100, 200],
      data: {
        url: data.url || '/'
      }
    };
    
    event.waitUntil(
      self.registration.showNotification(data.title || 'Cally', options)
    );
  }
});

// Handle notification clicks
self.addEventListener('notificationclick', event => {
  event.notification.close();
  
  event.waitUntil(
    clients.openWindow(event.notification.data.url || '/')
  );
});

console.log('🤖 Cally Service Worker: Loaded and ready!');
