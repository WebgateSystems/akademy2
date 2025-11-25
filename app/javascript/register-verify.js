document.addEventListener('DOMContentLoaded', () => {
	const form = document.querySelector('.auth-form');
	const otpInputs = Array.from(document.querySelectorAll('.otp-inputs input'));
	const actionButton = document.querySelector('.js-verify-action');
	if (!form || !otpInputs.length || !actionButton) return;

	// 🔥 берем путь из data-next-url формы
	const nextUrl = form.dataset.nextUrl;

	let timerSeconds = 59;
	let resendAvailable = false;
	let timerId = null;

	const formatSeconds = (value) => `0:${String(value).padStart(2, '0')}`;

	const setButtonState = (label, disabled, action = 'resend') => {
		actionButton.textContent = label;
		actionButton.disabled = disabled;
		actionButton.dataset.action = action;
		actionButton.classList.toggle('auth-submit--disabled', disabled);
		actionButton.classList.toggle('auth-submit--primary', !disabled && action === 'verify');
	};

	const showTimerLabel = () => {
		if (resendAvailable) {
			setButtonState('Resend code', false, 'resend');
		} else {
			setButtonState(`Resend (in ${formatSeconds(timerSeconds)})`, true, 'resend');
		}
	};

	const hasAnyValue = () => otpInputs.some((input) => input.value.trim() !== '');
	const isCodeComplete = () => otpInputs.every((input) => input.value.trim().length === 1);

	const updateActionState = () => {
		if (hasAnyValue()) {
			const canSubmit = isCodeComplete();
			setButtonState('Verify code', !canSubmit, 'verify');
		} else {
			showTimerLabel();
		}
	};

	const tickTimer = () => {
		if (timerSeconds <= 0) {
			resendAvailable = true;
			clearInterval(timerId);
			timerId = null;
			if (!hasAnyValue()) showTimerLabel();
			return;
		}
		timerSeconds -= 1;
		if (!hasAnyValue()) showTimerLabel();
	};

	const startTimer = () => {
		if (timerId) clearInterval(timerId);
		timerSeconds = 59;
		resendAvailable = false;
		showTimerLabel();
		timerId = setInterval(tickTimer, 1000);
	};

	const sanitizeInput = (input, index) => {
		const digitsOnly = input.value.replace(/\D/g, '');
		input.value = digitsOnly.slice(-1);
		if (input.value && index < otpInputs.length - 1) {
			otpInputs[index + 1].focus();
		}
		updateActionState();
	};

	otpInputs.forEach((input, index) => {
		input.addEventListener('input', () => sanitizeInput(input, index));
		input.addEventListener('keydown', (event) => {
			if (event.key === 'Backspace' && !input.value && index > 0) {
				otpInputs[index - 1].focus();
			}
		});
	});

	actionButton.addEventListener('click', () => {
		const action = actionButton.dataset.action;
	
		if (action === 'verify' && !actionButton.disabled) {
			form.submit();
		}
	
		else if (action === 'resend' && resendAvailable) {
			fetch('/register/resend-code', {
				method: 'GET',
				headers: {
					'Accept': 'application/json',
					'X-Requested-With': 'XMLHttpRequest'
				}
			})
			.then(r => r.json())
			.then(() => {
				startTimer();
			})
			.catch(() => {
				alert("Something went wrong. Try again.");
			});
		}
	});
	

	startTimer();
	updateActionState();
});
