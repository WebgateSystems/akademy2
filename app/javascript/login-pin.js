/**
 * PIN input handler
 * Manages 4 separate digit inputs for PIN entry (login, password reset, etc.)
 */
document.addEventListener('DOMContentLoaded', () => {
	// Initialize PIN groups
	initPinGroup('login-pin-hidden', '.login-pin-digit:not(.reset-pin-digit):not(.reset-pin-confirm-digit)', true);
	initPinGroup('reset-pin-hidden', '.reset-pin-digit', false);
	initPinGroup('reset-pin-confirm-hidden', '.reset-pin-confirm-digit', false);

	function initPinGroup(hiddenInputId, inputSelector, autoSubmit) {
		const hiddenInput = document.getElementById(hiddenInputId);
		const pinInputs = document.querySelectorAll(inputSelector);
		const form = hiddenInput?.closest('form');

		if (!pinInputs.length || !hiddenInput || !form) return;

		const updateHiddenField = () => {
			const pin = Array.from(pinInputs).map(input => input.value).join('');
			hiddenInput.value = pin;
			return pin;
		};

		const tryAutoSubmit = () => {
			if (!autoSubmit) return;
			const pin = updateHiddenField();
			// Auto-submit when all 4 digits are entered
			if (pin.length === 4) {
				form.submit();
			}
		};

		const focusNextInput = (currentIndex) => {
			if (currentIndex < pinInputs.length - 1) {
				pinInputs[currentIndex + 1].focus();
				pinInputs[currentIndex + 1].select();
			}
		};

		const focusPrevInput = (currentIndex) => {
			if (currentIndex > 0) {
				pinInputs[currentIndex - 1].focus();
				pinInputs[currentIndex - 1].select();
			}
		};

		// Find the next PIN group to focus after completing this one
		const focusNextGroup = () => {
			if (hiddenInputId === 'reset-pin-hidden') {
				const confirmInputs = document.querySelectorAll('.reset-pin-confirm-digit');
				if (confirmInputs.length > 0) {
					confirmInputs[0].focus();
				}
			}
		};

		pinInputs.forEach((input, index) => {
			// Handle input
			input.addEventListener('input', (e) => {
				// Only allow digits
				const value = e.target.value.replace(/\D/g, '');
				e.target.value = value.slice(0, 1);

				updateHiddenField();

				// Auto-advance to next field if digit entered
				if (value.length >= 1) {
					if (index === pinInputs.length - 1) {
						// Last digit entered
						if (autoSubmit) {
							tryAutoSubmit();
						} else {
							// Move to next PIN group if available
							focusNextGroup();
						}
					} else {
						focusNextInput(index);
					}
				}
			});

			// Handle keydown for backspace and arrow navigation
			input.addEventListener('keydown', (e) => {
				if (e.key === 'Backspace') {
					if (e.target.value === '') {
						// Move to previous input if current is empty
						focusPrevInput(index);
					} else {
						// Clear current input
						e.target.value = '';
						updateHiddenField();
					}
					e.preventDefault();
				} else if (e.key === 'ArrowLeft') {
					focusPrevInput(index);
					e.preventDefault();
				} else if (e.key === 'ArrowRight') {
					focusNextInput(index);
					e.preventDefault();
				} else if (e.key === 'Delete') {
					e.target.value = '';
					updateHiddenField();
					e.preventDefault();
				}
			});

			// Handle paste
			input.addEventListener('paste', (e) => {
				e.preventDefault();
				const pastedData = (e.clipboardData || window.clipboardData).getData('text');
				const digits = pastedData.replace(/\D/g, '').slice(0, 4);

				digits.split('').forEach((digit, i) => {
					if (pinInputs[i]) {
						pinInputs[i].value = digit;
					}
				});

				updateHiddenField();

				// Auto-submit if all 4 digits were pasted and autoSubmit is enabled
				if (digits.length === 4 && autoSubmit) {
					tryAutoSubmit();
				} else if (digits.length === 4) {
					// Move to next PIN group
					focusNextGroup();
				} else {
					// Focus the next empty input or the last one
					const nextEmptyIndex = Array.from(pinInputs).findIndex(inp => inp.value === '');
					if (nextEmptyIndex !== -1) {
						pinInputs[nextEmptyIndex].focus();
					} else {
						pinInputs[pinInputs.length - 1].focus();
					}
				}
			});

			// Select all on focus
			input.addEventListener('focus', () => {
				input.select();
			});
		});
	}
});
