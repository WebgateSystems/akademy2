document.addEventListener('DOMContentLoaded', () => {
	const form = document.querySelector('.auth-form');
	const submitButton = form?.querySelector('.auth-submit');
	if (!form || !submitButton) return;

	const validators = {
		first_name: {
			input: form.querySelector('input[name="first_name"]'),
			validate: (value) => /^[A-Za-z\s'-]{2,}$/.test(value.trim()),
			message: 'Please enter at least 2 letters.',
		},
		last_name: {
			input: form.querySelector('input[name="last_name"]'),
			validate: (value) => /^[A-Za-z\s'-]{2,}$/.test(value.trim()),
			message: 'Please enter at least 2 letters.',
		},
		date_of_birth: {
			input: form.querySelector('input[name="date_of_birth"]'),
			validate: (value) => {
				if (!/^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[0-2])\.(19|20)\d{2}$/.test(value)) return false;
				const [day, month, year] = value.split('.').map(Number);
				const date = new Date(year, month - 1, day);
				return date.getDate() === day && date.getMonth() === month - 1 && date.getFullYear() === year;
			},
			message: 'Use format DD.MM.YYYY and a real date.',
		},
		email: {
			input: form.querySelector('input[name="email"]'),
			validate: (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value),
			message: 'Enter a valid email address.',
		},
		phone: {
			input: form.querySelector('input[name="phone"]'),
			validate: (value) => /^\+?[0-9\s-]{10,}$/.test(value.trim()),
			message: 'Enter at least 10 digits (you can include +, spaces, or dashes).',
		},
		marketing_opt_in: {
			input: form.querySelector('input[name="marketing_opt_in"]'),
			validate: (value, input) => input ? input.checked === true : false,
			message: 'You must agree to receive communications.',
		},
	};

	const toggleButtonState = (isEnabled) => {
		submitButton.disabled = !isEnabled;
		submitButton.classList.toggle('auth-submit--disabled', !isEnabled);
		submitButton.classList.toggle('auth-submit--primary', isEnabled);
	};

	const isFormValid = () =>
		Object.values(validators).every(({ input, validate }) => {
			if (!input) return false;
			return validate(input.value, input);
		});

	Object.values(validators).forEach(({ input }) => {
		if (!input) return;
		const eventName = input.type === 'checkbox' ? 'change' : 'input';
		input.addEventListener(eventName, () => {
			input.setCustomValidity('');
			toggleButtonState(isFormValid());
		});
	});

	form.addEventListener('submit', (event) => {
		let firstInvalidInput = null;

		Object.values(validators).forEach(({ input, validate, message }) => {
			if (!input) return;
			if (!validate(input.value, input)) {
				input.setCustomValidity(message);
				firstInvalidInput = firstInvalidInput || input;
			} else {
				input.setCustomValidity('');
			}
		});

		const valid = !firstInvalidInput;
		toggleButtonState(valid);

		if (!valid) {
			event.preventDefault();
			firstInvalidInput.reportValidity();
		}
	});

	toggleButtonState(isFormValid());
});
