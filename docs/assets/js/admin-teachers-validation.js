document.addEventListener('DOMContentLoaded', () => {
	const form = document.getElementById('teacher-edit-form');
	if (!form) return;

	const validators = [
		{
			input: form.querySelector('#teacher-name'),
			validate: (value) => /^[A-Za-zÀ-ÿ\s'-]{2,}$/.test(value.trim()),
			message: 'Enter at least 2 letters.',
		},
		{
			input: form.querySelector('#teacher-birth'),
			validate: (value) => {
				if (!/^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[0-2])\.(19|20)\d{2}$/.test(value)) return false;
				const [day, month, year] = value.split('.').map(Number);
				const date = new Date(year, month - 1, day);
				return date.getDate() === day && date.getMonth() === month - 1 && date.getFullYear() === year;
			},
			message: 'Use DD.MM.YYYY and provide a valid date.',
		},
		{
			input: form.querySelector('#teacher-email'),
			validate: (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value),
			message: 'Enter a valid email address.',
		},
		{
			input: form.querySelector('#teacher-phone'),
			validate: (value) => /^\+?[0-9\s-]{9,}$/.test(value.trim()),
			message: 'Enter at least 9 digits (you can use +, spaces, or dashes).',
		},
		{
			input: form.querySelector('#teacher-subjects'),
			validate: (value) => value.trim().length > 0,
			message: 'Subjects cannot be empty.',
		},
	];

	validators.forEach(({ input }) => {
		input?.addEventListener('input', () => input.setCustomValidity(''));
	});

	form.addEventListener('submit', (event) => {
		let firstInvalid = null;

		validators.forEach(({ input, validate, message }) => {
			if (!input) return;
			if (!validate(input.value)) {
				input.setCustomValidity(message);
				firstInvalid = firstInvalid || input;
			} else {
				input.setCustomValidity('');
			}
		});

		if (firstInvalid) {
			event.preventDefault();
			firstInvalid.reportValidity();
		}
	});
});
