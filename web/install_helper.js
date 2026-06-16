// RKFM Install Helper — platform-aware install for Android / iOS / Web PWA
(function () {
  const APK_URL = 'https://github.com/msicoresolution-04/rk-fm975/releases/latest/download/rkfm-97.5.apk';
  let deferredPrompt = null;

  function detectPlatform() {
    const ua = navigator.userAgent || navigator.vendor || '';
    if (/android/i.test(ua)) return 'android';
    if (/iPad|iPhone|iPod/.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)) return 'ios';
    if (/Chrome|Edg/i.test(ua) && !/Mobile/i.test(ua)) return 'desktop';
    return 'web';
  }

  function isStandalone() {
    return window.matchMedia('(display-mode: standalone)').matches
      || window.navigator.standalone === true;
  }

  function platformLabel(p) {
    return { android: 'Android', ios: 'iOS', web: 'Web', desktop: 'Desktop' }[p] || 'Web';
  }

  const state = {
    platform: detectPlatform(),
    canInstall: true,
    isInstalled: isStandalone(),
    platformLabel: platformLabel(detectPlatform()),
  };

  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault();
    deferredPrompt = e;
    state.canInstall = true;
  });

  window.addEventListener('appinstalled', function () {
    state.isInstalled = true;
    state.canInstall = false;
    deferredPrompt = null;
  });

  function showIosGuide() {
    const overlay = document.createElement('div');
    overlay.id = 'rkfm-ios-guide';
    overlay.innerHTML = `
      <div style="position:fixed;inset:0;background:rgba(0,0,0,0.85);z-index:99999;display:flex;align-items:center;justify-content:center;padding:24px;">
        <div style="background:#161B22;border:1px solid #30363D;border-radius:12px;padding:32px;max-width:420px;text-align:center;color:#F0F6FC;font-family:system-ui,sans-serif;">
          <div style="font-size:48px;margin-bottom:16px;">📲</div>
          <h2 style="margin:0 0 12px;font-size:20px;">Install on iOS</h2>
          <p style="color:#8B949E;font-size:14px;line-height:1.6;margin:0 0 20px;">
            1. Tap the <strong>Share</strong> button (□↑) in Safari<br>
            2. Scroll down and tap <strong>"Add to Home Screen"</strong><br>
            3. Tap <strong>Add</strong> to install RKFM 97.5
          </p>
          <button onclick="document.getElementById('rkfm-ios-guide').remove()" 
            style="background:#2EA043;color:white;border:none;padding:12px 32px;border-radius:8px;font-size:14px;font-weight:600;cursor:pointer;">
            GOT IT
          </button>
        </div>
      </div>`;
    document.body.appendChild(overlay);
  }

  function showAndroidGuide() {
    const overlay = document.createElement('div');
    overlay.id = 'rkfm-android-guide';
    overlay.innerHTML = `
      <div style="position:fixed;inset:0;background:rgba(0,0,0,0.85);z-index:99999;display:flex;align-items:center;justify-content:center;padding:24px;">
        <div style="background:#161B22;border:1px solid #30363D;border-radius:12px;padding:32px;max-width:420px;text-align:center;color:#F0F6FC;font-family:system-ui,sans-serif;">
          <div style="font-size:48px;margin-bottom:16px;">📥</div>
          <h2 style="margin:0 0 12px;font-size:20px;">Install on Android</h2>
          <p style="color:#8B949E;font-size:14px;line-height:1.6;margin:0 0 20px;">
            APK download started.<br>
            Open the downloaded file and tap <strong>Install</strong>.<br>
            Allow installation from this source if prompted.
          </p>
          <button onclick="document.getElementById('rkfm-android-guide').remove()" 
            style="background:#2EA043;color:white;border:none;padding:12px 32px;border-radius:8px;font-size:14px;font-weight:600;cursor:pointer;">
            GOT IT
          </button>
        </div>
      </div>`;
    document.body.appendChild(overlay);
  }

  window.rkfmInstall = {
    get platform() { return state.platform; },
    get canInstall() { return state.canInstall && !state.isInstalled; },
    get isInstalled() { return state.isInstalled; },
    get platformLabel() { return state.platformLabel; },

    checkState: function () {
      state.platform = detectPlatform();
      state.platformLabel = platformLabel(state.platform);
      state.isInstalled = isStandalone();
      if (state.isInstalled) state.canInstall = false;
      return Promise.resolve();
    },

    install: function () {
      const p = state.platform;

      if (p === 'android') {
        const link = document.createElement('a');
        link.href = APK_URL;
        link.download = 'rkfm-97.5.apk';
        link.click();
        showAndroidGuide();
        return Promise.resolve();
      }

      if (p === 'ios') {
        showIosGuide();
        return Promise.resolve();
      }

      if (deferredPrompt) {
        deferredPrompt.prompt();
        return deferredPrompt.userChoice.then(function (choice) {
          deferredPrompt = null;
          if (choice.outcome === 'accepted') {
            state.isInstalled = true;
            state.canInstall = false;
          }
        });
      }

      // Desktop / fallback PWA
      if ('serviceWorker' in navigator) {
        alert('To install: Click the install icon (⊕) in your browser address bar, or use browser menu → Install App.');
      }
      return Promise.resolve();
    }
  };
})();
