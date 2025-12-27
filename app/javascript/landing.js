// Landing page theme handling - runs immediately (not deferred)
(function() {
  const STORAGE_KEY = 'theme';

  function getStoredTheme() {
    return localStorage.getItem(STORAGE_KEY);
  }

  function getSystemTheme() {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function applyTheme(theme) {
    const isDark = theme === 'dark';
    document.documentElement.classList.toggle('theme-dark', isDark);
    document.documentElement.setAttribute('data-theme', theme);
    updateVideoPoster(theme);
  }

  function updateVideoPoster(theme) {
    const video = document.getElementById('hero-intro-video');
    if (!video) return;

    const posterLight = video.dataset.posterLight;
    const posterDark = video.dataset.posterDark;
    const newPoster = theme === 'dark' ? posterDark : posterLight;

    if (newPoster && video.poster !== newPoster) {
      video.poster = newPoster;
    }
  }

  // Apply theme immediately on script load
  const storedTheme = getStoredTheme();
  const effectiveTheme = storedTheme || getSystemTheme();
  applyTheme(effectiveTheme);

  // Setup toggle, year, and poster after DOM is ready
  document.addEventListener('DOMContentLoaded', function() {
    // Update video poster (in case video wasn't in DOM during initial applyTheme)
    updateVideoPoster(effectiveTheme);

    const toggle = document.getElementById('themeToggle');
    const yearEl = document.getElementById('currentYear');
    
    // Set current year
    if (yearEl) {
      yearEl.textContent = new Date().getFullYear();
    }

    // Theme toggle - single icon button (sun in dark mode, moon in light mode)
    if (toggle) {
      toggle.addEventListener('click', function() {
        const currentTheme = document.documentElement.classList.contains('theme-dark') ? 'dark' : 'light';
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        
        localStorage.setItem(STORAGE_KEY, newTheme);
        applyTheme(newTheme);
      });
    }
  });
})();
