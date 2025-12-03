const THEME_STORAGE_KEY = 'theme';
const rootElement = document.documentElement;
const mediaQuery = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;
const savedTheme = localStorage.getItem(THEME_STORAGE_KEY);
const prefersDark = mediaQuery?.matches ?? false;
const initialIsDark = savedTheme ? savedTheme === 'dark' : prefersDark;

// Apply theme to document
function applyTheme(isDark) {
	rootElement.classList.toggle('theme-dark', isDark);
	rootElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
	localStorage.setItem(THEME_STORAGE_KEY, isDark ? 'dark' : 'light');
}

// Set initial theme immediately
applyTheme(initialIsDark);

// Handle toggle button click
document.addEventListener('DOMContentLoaded', () => {
	const toggleBtn = document.getElementById('theme-toggle-btn');
	if (toggleBtn) {
		toggleBtn.addEventListener('click', () => {
			const isDark = rootElement.classList.contains('theme-dark');
			applyTheme(!isDark);
		});
	}
});
