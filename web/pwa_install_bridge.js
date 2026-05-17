// PWA install bridge for Flutter web (beforeinstallprompt + standalone detection).
(function () {
  let deferredPrompt = null;

  window.addEventListener("beforeinstallprompt", function (e) {
    e.preventDefault();
    deferredPrompt = e;
    window.__pwaInstallAvailable = true;
    window.dispatchEvent(new Event("pwa-install-available"));
  });

  window.addEventListener("appinstalled", function () {
    deferredPrompt = null;
    window.__pwaInstallAvailable = false;
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
})();
