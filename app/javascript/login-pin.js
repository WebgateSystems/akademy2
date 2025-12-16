/**
 * PIN input handler
 * Manages 4 separate digit inputs for PIN entry (login, password reset, etc.)
 */
document.addEventListener('DOMContentLoaded', () => {
	// Initialize phone input formatting
	initPhoneInput();
	
	// Initialize PIN groups
	initPinGroup('login-pin-hidden', '.login-pin-digit:not(.reset-pin-digit):not(.reset-pin-confirm-digit)', true);
	initPinGroup('reset-pin-hidden', '.reset-pin-digit', false);
	initPinGroup('reset-pin-confirm-hidden', '.reset-pin-confirm-digit', false);
	
	/**
	 * Phone input with +48 prefix and formatting (123 456 789)
	 */
	function initPhoneInput() {
		const displayInput = document.getElementById('phone-display');
		const hiddenInput = document.getElementById('phone-hidden');
		const firstPinInput = document.querySelector('.login-pin-digit[data-pin-index="0"]');
		
		if (!displayInput || !hiddenInput) return;
		
		// Format phone number for display: +48 123 456 789
		function formatPhoneDisplay(value) {
			// Extract just digits and any leading +
			let hasPlus = value.startsWith('+');
			let digits = value.replace(/\D/g, '');
			
			// Limit to country code (2) + phone number (9) = 11 digits max
			digits = digits.slice(0, 11);
			
			// Build formatted string
			let result = '';
			
			if (hasPlus || digits.length > 0) {
				result = '+';
			}
			
			// Country code (first 2 digits after +)
			if (digits.length > 0) {
				result += digits.slice(0, 2);
			}
			
			// Remaining digits in groups of 3
			const remaining = digits.slice(2);
			if (remaining.length > 0) {
				result += ' ' + remaining.slice(0, 3);
			}
			if (remaining.length > 3) {
				result += ' ' + remaining.slice(3, 6);
			}
			if (remaining.length > 6) {
				result += ' ' + remaining.slice(6, 9);
			}
			
			return result;
		}
		
		// Get clean phone value for submission: +48123456789
		function getCleanPhone(value) {
			const hasPlus = value.startsWith('+');
			const digits = value.replace(/\D/g, '');
			return (hasPlus ? '+' : '') + digits;
		}
		
		// Check if phone number is valid (country code + 9 digits)
		function isPhoneValid(value) {
			const digits = value.replace(/\D/g, '');
			// Valid: 2 digit country code + 9 digit phone = 11 digits total
			return digits.length === 11;
		}
		
		// Check if user has started typing phone number (beyond just +48)
		function hasStartedTyping(value) {
			const digits = value.replace(/\D/g, '');
			// More than just country code
			return digits.length > 2;
		}
		
		// Update validation state (border color)
		function updateValidation() {
			const value = displayInput.value;
			
			if (!hasStartedTyping(value)) {
				// Not started yet - neutral
				displayInput.classList.remove('login-phone--valid', 'login-phone--invalid');
			} else if (isPhoneValid(value)) {
				// Valid - green
				displayInput.classList.remove('login-phone--invalid');
				displayInput.classList.add('login-phone--valid');
			} else {
				// Invalid - red
				displayInput.classList.remove('login-phone--valid');
				displayInput.classList.add('login-phone--invalid');
			}
		}
		
		// Update hidden field with clean value
		function updateHiddenField() {
			hiddenInput.value = getCleanPhone(displayInput.value);
		}
		
		// Handle input - format as user types
		displayInput.addEventListener('input', (e) => {
			const cursorPos = e.target.selectionStart;
			const oldValue = e.target.value;
			const oldLength = oldValue.length;
			
			// Format the value (this also limits to max digits)
			const formatted = formatPhoneDisplay(oldValue);
			e.target.value = formatted;
			
			// Try to maintain cursor position
			const newLength = formatted.length;
			const diff = newLength - oldLength;
			let newCursorPos = cursorPos + diff;
			
			// Adjust cursor if it's after a space we just added
			if (newCursorPos > 0 && formatted[newCursorPos - 1] === ' ') {
				newCursorPos++;
			}
			
			// Keep cursor within bounds
			newCursorPos = Math.min(newCursorPos, formatted.length);
			newCursorPos = Math.max(newCursorPos, 0);
			
			e.target.setSelectionRange(newCursorPos, newCursorPos);
			
			updateHiddenField();
			updateValidation();
		});
		
		// Handle keydown for Tab to go directly to PIN
		displayInput.addEventListener('keydown', (e) => {
			if (e.key === 'Tab' && !e.shiftKey && firstPinInput) {
				e.preventDefault();
				firstPinInput.focus();
			}
		});
		
		// On focus, if empty, prefill with +48
		displayInput.addEventListener('focus', () => {
			if (displayInput.value === '' || displayInput.value === '+') {
				displayInput.value = '+48';
				updateHiddenField();
				// Move cursor to end
				setTimeout(() => {
					displayInput.setSelectionRange(3, 3);
				}, 0);
			}
		});
		
		// Initial update
		updateHiddenField();
		updateValidation();
	}

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
