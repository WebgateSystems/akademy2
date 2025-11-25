const THEME_STORAGE_KEY = 'ust-theme';
const rootElement = document.documentElement;
const mediaQuery = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;
const savedTheme = localStorage.getItem(THEME_STORAGE_KEY);
const prefersDark = mediaQuery?.matches ?? false;
const initialIsDark = savedTheme ? savedTheme === 'dark' : prefersDark;

rootElement.classList.toggle('theme-dark', initialIsDark);
if (!savedTheme) {
	localStorage.setItem(THEME_STORAGE_KEY, initialIsDark ? 'dark' : 'light');
}

document.addEventListener('DOMContentLoaded', () => {
	const trigger = document.querySelector('[data-theme-toggle-trigger]');
	const panel = document.getElementById('theme-switcher');
	const checkbox = document.getElementById('theme-toggle-input');

	const setTheme = (isDark) => {
		rootElement.classList.toggle('theme-dark', isDark);
		localStorage.setItem(THEME_STORAGE_KEY, isDark ? 'dark' : 'light');
		if (checkbox) {
			checkbox.checked = isDark;
		}
	};

	if (checkbox) {
		checkbox.checked = initialIsDark;
		checkbox.addEventListener('change', () => setTheme(checkbox.checked));
	}

	const hidePanel = () => {
		if (!panel || panel.hasAttribute('hidden')) return;
		panel.setAttribute('hidden', '');
		trigger?.setAttribute('aria-expanded', 'false');
	};

	trigger?.addEventListener('click', (event) => {
		event.stopPropagation();
		if (!panel) return;
		const willOpen = panel.hasAttribute('hidden');
		if (willOpen) {
			panel.removeAttribute('hidden');
			trigger.setAttribute('aria-expanded', 'true');
			checkbox?.focus();
		} else {
			hidePanel();
		}
	});

	document.addEventListener('click', (event) => {
		if (!panel || panel.hasAttribute('hidden')) return;
		if (panel.contains(event.target) || trigger?.contains(event.target)) {
			return;
		}
		hidePanel();
	});
});
