document.addEventListener('DOMContentLoaded', () => {
	const form = document.querySelector('.digit-code-form');
	const hiddenInput = document.querySelector('.digit-code-hidden');
	const dots = document.querySelectorAll('.digit-code-input__dot');

	if (!form || !hiddenInput || !dots.length) return;

	const maxDigits = dots.length;

	const updateDots = () => {
		const chars = hiddenInput.value.split('');
		dots.forEach((dot, index) => {
			dot.classList.toggle('is-filled', Boolean(chars[index]));
		});
	};

	const sanitizeValue = () => {
		const digitsOnly = hiddenInput.value.replace(/\D/g, '').slice(0, maxDigits);
		if (digitsOnly !== hiddenInput.value) {
			hiddenInput.value = digitsOnly;
		}
		updateDots();

		if (hiddenInput.value.length === maxDigits) {
			form.submit();
		}
	};

	hiddenInput.addEventListener('input', sanitizeValue);
	hiddenInput.addEventListener('focus', () => hiddenInput.select());

	form.addEventListener('click', () => hiddenInput.focus());

	sanitizeValue();
	hiddenInput.focus();
});
