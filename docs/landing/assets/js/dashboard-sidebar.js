document.addEventListener('DOMContentLoaded', () => {
	const SIDEBAR_COLLAPSED_KEY = 'dashboardSidebarCollapsed';
	const app = document.querySelector('[data-dashboard-app]');
	const toggleButton = document.querySelector('[data-sidebar-toggle]');
	const overlay = document.querySelector('[data-sidebar-overlay]');
	const collapseToggle = document.querySelector('[data-sidebar-collapse-toggle]');
	if (!app || !toggleButton || !overlay) return;

	const navButtons = app.querySelectorAll('.dashboard-nav__button');

	const closeSidebar = () => {
		app.classList.remove('dashboard-app--sidebar-open');
	};

	const toggleSidebar = () => {
		app.classList.toggle('dashboard-app--sidebar-open');
	};

	const updateCollapseToggleState = () => {
		if (!collapseToggle) return;
		const isDesktop = window.matchMedia('(min-width: 1024px)').matches;
		if (!isDesktop) {
			app.classList.remove('dashboard-app--sidebar-collapsed');
			collapseToggle.setAttribute('aria-expanded', 'true');
			collapseToggle.setAttribute('aria-label', 'Collapse sidebar');
			return;
		}

		const storedCollapsed = localStorage.getItem(SIDEBAR_COLLAPSED_KEY) === 'true';
		if (storedCollapsed) {
			app.classList.add('dashboard-app--sidebar-collapsed');
		} else {
			app.classList.remove('dashboard-app--sidebar-collapsed');
		}

		const isCollapsed = app.classList.contains('dashboard-app--sidebar-collapsed');
		collapseToggle.setAttribute('aria-expanded', String(!isCollapsed));
		collapseToggle.setAttribute('aria-label', isCollapsed ? 'Expand sidebar' : 'Collapse sidebar');
	};

	if (collapseToggle) {
		collapseToggle.addEventListener('click', () => {
			if (!window.matchMedia('(min-width: 1024px)').matches) return;
			const isCollapsed = app.classList.toggle('dashboard-app--sidebar-collapsed');
			localStorage.setItem(SIDEBAR_COLLAPSED_KEY, String(isCollapsed));
			updateCollapseToggleState();
		});
	}

	toggleButton.addEventListener('click', toggleSidebar);
	overlay.addEventListener('click', closeSidebar);

	navButtons.forEach((button) => {
		button.addEventListener('click', () => {
			if (window.matchMedia('(max-width: 768px)').matches) {
				closeSidebar();
			}
		});
	});

	window.addEventListener('resize', () => {
		if (!window.matchMedia('(max-width: 768px)').matches) {
			closeSidebar();
		}
		updateCollapseToggleState();
	});

	updateCollapseToggleState();
});
