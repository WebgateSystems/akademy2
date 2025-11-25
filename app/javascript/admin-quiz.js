document.addEventListener('DOMContentLoaded', () => {
	const dots = document.querySelectorAll('.js-quiz-tooltip');
	if (!dots.length) return;

	const tooltip = document.createElement('div');
	tooltip.className = 'quiz-tooltip';
	document.body.appendChild(tooltip);

	const hideTooltip = () => {
		tooltip.classList.remove('is-visible');
	};

	const showTooltip = (target) => {
		const question = target.dataset.question || '';
		const questionText = target.dataset.questionText || '';
		const answer = target.dataset.answer || '';

		tooltip.innerHTML = `
			<strong>${question}</strong>
			<p>${questionText}</p>
			<span>Pupil answer:</span>
			<p>${answer}</p>
		`;

		tooltip.classList.add('is-visible');

		const rect = target.getBoundingClientRect();
		const tooltipRect = tooltip.getBoundingClientRect();
		const top = rect.top + window.scrollY - tooltipRect.height - 14;
		let left = rect.left + window.scrollX + rect.width / 2 - tooltipRect.width / 2;

		const minLeft = 16;
		const maxLeft = window.innerWidth - tooltipRect.width - 16;

		if (left < minLeft) {
			left = minLeft;
		} else if (left > maxLeft) {
			left = maxLeft;
		}

		tooltip.style.top = `${top}px`;
		tooltip.style.left = `${left}px`;
	};

	dots.forEach((dot) => {
		dot.addEventListener('mouseenter', () => showTooltip(dot));
		dot.addEventListener('mouseleave', hideTooltip);
		dot.addEventListener('focus', () => showTooltip(dot));
		dot.addEventListener('blur', hideTooltip);
	});
});
