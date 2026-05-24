// PWA install bridge for Flutter web (beforeinstallprompt + standalone detection).
(function () {
  let deferredPrompt = null;

  window.addEventListener("beforeinstallprompt", function (e) {
    // Defer the browser prompt so the app can show its own install UI.
    // This hides Chrome's default omnibar install icon until prompt() runs.
    e.preventDefault();
    deferredPrompt = e;
    window.__pwaInstallAvailable = true;
    window.dispatchEvent(new Event("pwa-install-available"));
  });

  window.addEventListener("appinstalled", function () {
    deferredPrompt = null;
    window.__pwaInstallAvailable = false;
    window.dispatchEvent(new Event("pwa-installed"));
  });

  window.pwaIsStandalone = function () {
    const standaloneMedia = window.matchMedia("(display-mode: standalone)");
    const iosStandalone = window.navigator.standalone === true;
    return (standaloneMedia && standaloneMedia.matches) || iosStandalone;
  };

  window.pwaInstallAvailable = function () {
    return deferredPrompt != null;
  };

  window.pwaInstallPrompt = async function () {
    if (!deferredPrompt) {
      return "unavailable";
    }
    deferredPrompt.prompt();
    const choice = await deferredPrompt.userChoice;
    deferredPrompt = null;
    window.__pwaInstallAvailable = false;
    return choice.outcome === "accepted" ? "accepted" : "dismissed";
  };

  window.pwaListenInstallAvailable = function (callback) {
    window.addEventListener("pwa-install-available", callback);
  };

  window.pwaCancelInstallAvailable = function (callback) {
    window.removeEventListener("pwa-install-available", callback);
  };

  window.pwaListenInstalled = function (callback) {
    window.addEventListener("pwa-installed", callback);
  };

  window.pwaCancelInstalled = function (callback) {
    window.removeEventListener("pwa-installed", callback);
  };

  window.reviewNotificationSupported = function () {
    return "Notification" in window;
  };

  window.reviewNotificationPermission = function () {
    if (!window.reviewNotificationSupported()) {
      return "unsupported";
    }
    return window.Notification.permission || "default";
  };

  window.reviewNotificationRequestPermission = async function () {
    if (!window.reviewNotificationSupported()) {
      return "unsupported";
    }
    return await window.Notification.requestPermission();
  };

  window.reviewNotificationSetTapHandler = function (callback) {
    window.__reviewNotificationTapHandler = callback;
  };

  window.reviewNotificationConsumeTap = function () {
    const pending = window.__reviewNotificationPendingTap === true;
    window.__reviewNotificationPendingTap = false;
    return pending;
  };

  window.reviewNotificationShow = function (title, body) {
    if (
      !window.reviewNotificationSupported() ||
      window.Notification.permission !== "granted"
    ) {
      return;
    }
    const notification = new window.Notification(title, { body: body });
    notification.onclick = function () {
      window.__reviewNotificationPendingTap = true;
      window.focus();
      if (typeof window.__reviewNotificationTapHandler === "function") {
        window.__reviewNotificationTapHandler();
      }
      window.dispatchEvent(new Event("review-notification-tap"));
      notification.close();
    };
  };
})();
