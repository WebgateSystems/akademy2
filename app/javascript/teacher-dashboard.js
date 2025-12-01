// Teacher Dashboard JavaScript
document.addEventListener('DOMContentLoaded', () => {
  const app = document.querySelector('[data-dashboard-app]');
  if (!app) return;

  const config = window.DASHBOARD_CONFIG || {};
  const copyCodeBtn = document.querySelector('[data-copy-code]');
  const downloadQrBtn = document.querySelector('[data-download-qr]');

  // Copy school code
  if (copyCodeBtn) {
    copyCodeBtn.addEventListener('click', async () => {
      const code = copyCodeBtn.dataset.code || config.schoolCode;
      if (!code) {
        console.warn('No school code available');
        return;
      }

      try {
        await navigator.clipboard.writeText(code);
        const originalText = copyCodeBtn.textContent;
        copyCodeBtn.textContent = 'Skopiowano!';
        setTimeout(() => {
          copyCodeBtn.textContent = originalText;
        }, 2000);
      } catch (err) {
        // Fallback for older browsers
        const textArea = document.createElement('textarea');
        textArea.value = code;
        textArea.style.position = 'fixed';
        textArea.style.opacity = '0';
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
        copyCodeBtn.textContent = 'Skopiowano!';
        setTimeout(() => {
          copyCodeBtn.textContent = 'Copy code';
        }, 2000);
      }
    });
  }

  // Download QR code
  if (downloadQrBtn) {
    downloadQrBtn.addEventListener('click', () => {
      const qrImage = document.querySelector('[data-qr-image]');
      if (qrImage) {
        const link = document.createElement('a');
        link.href = qrImage.src;
        link.download = `school-qr-code-${config.schoolCode || 'code'}.svg`;
        link.click();
      }
    });
  }

  // Theme toggle
  const themeToggleTrigger = document.querySelector('[data-theme-toggle-trigger]');
  const themeSwitcher = document.getElementById('theme-switcher');
  const themeToggleInput = document.getElementById('theme-toggle-input');

  if (themeToggleTrigger && themeSwitcher) {
    themeToggleTrigger.addEventListener('click', () => {
      const isExpanded = themeToggleTrigger.getAttribute('aria-expanded') === 'true';
      themeToggleTrigger.setAttribute('aria-expanded', !isExpanded);
      themeSwitcher.hidden = isExpanded;
    });

    // Close on click outside
    document.addEventListener('click', (e) => {
      if (!themeSwitcher.contains(e.target) && !themeToggleTrigger.contains(e.target)) {
        themeSwitcher.hidden = true;
        themeToggleTrigger.setAttribute('aria-expanded', 'false');
      }
    });
  }

  if (themeToggleInput) {
    // Load saved theme
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'dark') {
      document.documentElement.setAttribute('data-theme', 'dark');
      themeToggleInput.checked = true;
    }

    themeToggleInput.addEventListener('change', () => {
      const isDark = themeToggleInput.checked;
      document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
      localStorage.setItem('theme', isDark ? 'dark' : 'light');
    });
  }
});
