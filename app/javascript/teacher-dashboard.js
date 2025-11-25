document.addEventListener('DOMContentLoaded', () => {
	const makeCardsNavigable = (selector, defaultHref = '') => {
		document.querySelectorAll(selector).forEach((card) => {
			const href = card.dataset.href || defaultHref;
			if (!href) return;

			if (!card.hasAttribute('tabindex')) card.setAttribute('tabindex', '0');
			card.style.cursor = 'pointer';

			const navigateTo = () => {
				window.location.href = href;
			};

			card.addEventListener('click', navigateTo);
			card.addEventListener('keydown', (event) => {
				if (event.key === 'Enter' || event.key === ' ') {
					event.preventDefault();
					navigateTo();
				}
			});
		});
	};

	makeCardsNavigable('.class-result', '/pages/teacher/quiz-results.html');
	makeCardsNavigable('.school-profile-hero__stat-card[data-href]');
});
