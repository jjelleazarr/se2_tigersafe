importScripts('https://www.gstatic.com/firebasejs/9.6.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCDepDYLrTjWUHotnkm1t1de4XWPZFcfRY",
  authDomain: "tigersafe-test.firebaseapp.com",
  projectId: "tigersafe-test",
  storageBucket: "tigersafe-test.firebasestorage.app",
  messagingSenderId: "135221844856",
  appId: "1:135221844856:web:e323b0c0e20a99dea2068d",
  measurementId: "G-RJT36KC5RD"
});

const messaging = firebase.messaging();

// Optional: Customize notification handling
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png' // Optional: Path to your app icon
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
}); 