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
  }

  function updateToggleState(isLight) {
    const toggle = document.getElementById('themeToggle');
    if (toggle) {
      // aria-checked="true" means toggle is on the right (sun/light side)
      toggle.setAttribute('aria-checked', isLight ? 'true' : 'false');
    }
  }

  // Apply theme immediately on script load
  const storedTheme = getStoredTheme();
  const effectiveTheme = storedTheme || getSystemTheme();
  applyTheme(effectiveTheme);

  // Setup toggle and year after DOM is ready
  document.addEventListener('DOMContentLoaded', function() {
    const toggle = document.getElementById('themeToggle');
    const yearEl = document.getElementById('currentYear');
    
    // Set current year
    if (yearEl) {
      yearEl.textContent = new Date().getFullYear();
    }
    
    // Set initial toggle state
    const currentTheme = getStoredTheme() || getSystemTheme();
    updateToggleState(currentTheme === 'light');

    if (toggle) {
      toggle.addEventListener('click', function() {
        const currentTheme = document.documentElement.classList.contains('theme-dark') ? 'dark' : 'light';
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        
        localStorage.setItem(STORAGE_KEY, newTheme);
        applyTheme(newTheme);
        updateToggleState(newTheme === 'light');
      });
    }
  });
})();
