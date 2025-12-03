document.addEventListener("DOMContentLoaded", () => {
	const form = document.querySelector(".auth-form");
	if (!form) return;

	const submitButton = form.querySelector(".auth-submit");

	// Detect if this is a teacher or student registration form
	const isTeacherForm = document.getElementById("register_teacher_profile_form_first_name") !== null;
	const prefix = isTeacherForm ? "register_teacher_profile_form" : "register_profile_form";

	const fields = {
		first_name: document.getElementById(`${prefix}_first_name`),
		last_name: document.getElementById(`${prefix}_last_name`),
		birthdate: document.getElementById(`${prefix}_birthdate_display`),
		birthdateNative: document.getElementById(`${prefix}_birthdate`),
		email: document.getElementById(`${prefix}_email`),
		phone: document.getElementById(`${prefix}_phone`),
		password: document.getElementById(`${prefix}_password`),
		password_confirmation: document.getElementById(`${prefix}_password_confirmation`),
		marketing: document.getElementById(`${prefix}_marketing`),
	};

	// Date formatting helpers
	const formatDate = (value) => {
		if (!value) return '';
		const date = new Date(value);
		if (Number.isNaN(date.getTime())) return '';
		const pad = (num) => String(num).padStart(2, '0');
		return `${pad(date.getDate())}.${pad(date.getMonth() + 1)}.${date.getFullYear()}`;
	};

	const parseDisplayValue = (value) => {
		const trimmed = value.trim();
		if (!trimmed) return '';
		const match = trimmed.match(/^(\d{2})\.(\d{2})\.(\d{4})$/);
		if (!match) return '';
		const [, day, month, year] = match;
		const isoValue = `${year}-${month}-${day}`;
		const date = new Date(isoValue);
		if (Number.isNaN(date.getTime())) return '';
		return isoValue;
	};

	// Sync date picker display and native inputs
	if (fields.birthdate && fields.birthdateNative) {
		// Sync from native to display
		fields.birthdateNative.addEventListener('change', () => {
			if (fields.birthdateNative.value) {
				fields.birthdate.value = formatDate(fields.birthdateNative.value);
			}
			toggleButton();
		});

		// Sync from display to native (on blur)
		fields.birthdate.addEventListener('blur', () => {
			const parsed = parseDisplayValue(fields.birthdate.value);
			if (parsed) {
				fields.birthdateNative.value = parsed;
				fields.birthdate.value = formatDate(parsed);
			} else if (fields.birthdate.value.trim() === '') {
				fields.birthdateNative.value = '';
			}
			toggleButton();
		});

		// Auto-format while typing
		fields.birthdate.addEventListener('input', (e) => {
			let value = e.target.value.replace(/\D/g, ''); // Remove non-digits
			if (value.length > 8) value = value.slice(0, 8);
			
			// Format as DD.MM.YYYY
			let formatted = '';
			if (value.length > 0) {
				formatted = value.slice(0, 2);
				if (value.length > 2) {
					formatted += '.' + value.slice(2, 4);
					if (value.length > 4) {
						formatted += '.' + value.slice(4, 8);
					}
				}
			}
			e.target.value = formatted;
			toggleButton();
		});

		// When clicking on the right side (icon area), open native datepicker
		const datePickerWrapper = fields.birthdate.closest('.auth-date-picker');
		if (datePickerWrapper) {
			// Click handler for icon area (native input covers entire area, so clicking anywhere opens datepicker)
			// But we want to allow typing in display input, so we handle clicks on wrapper
			datePickerWrapper.addEventListener('click', (e) => {
				// If clicking directly on display input, allow normal behavior (typing)
				if (e.target === fields.birthdate) {
					return;
				}
				
				// Otherwise, open datepicker
				e.preventDefault();
				e.stopPropagation();
				fields.birthdateNative.focus();
				// Modern browsers support showPicker() method
				if (typeof fields.birthdateNative.showPicker === 'function') {
					fields.birthdateNative.showPicker();
				} else {
					// Fallback: trigger click on native input
					fields.birthdateNative.click();
				}
			});
		}
	}

	const validators = {
		first_name: (v) => v.trim().length >= 2,
		last_name: (v) => v.trim().length >= 2,
		birthdate: (v) => {
			// Check DD.MM.YYYY format
			if (!v) return false;
			const pattern = /^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[0-2])\.(19|20)\d{2}$/;
			if (!pattern.test(v)) return false;
			const [d, m, y] = v.split('.').map(Number);
			const date = new Date(y, m - 1, d);
			return date.getDate() === d && date.getMonth() === m - 1 && date.getFullYear() === y && date <= new Date();
		},
		birthdateNative: () => true, // Always valid, synced from birthdate display
		email: (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
		phone: (v) => /^\+?[0-9\s-]{10,}$/.test(v.trim()),
		password: (v) => v.length >= 6,
		password_confirmation: (v, input) => {
			const passwordField = fields.password;
			if (!passwordField) return true; // Skip if password field doesn't exist
			return v === passwordField.value && v.length >= 6;
		},
		marketing: (_, input) => {
			// Marketing is optional for teacher registration
			if (!input) return true;
			return input.checked === true;
		},
	};

	function isFormValid() {
		return Object.entries(fields).every(([key, input]) => {
			// Skip validation if field doesn't exist (e.g., birthdate/marketing for teacher registration)
			if (!input) return true;
			// Skip birthdateNative - it's synced from birthdate display
			if (key === 'birthdateNative') return true;
			const value = input.type === "checkbox" ? input.checked : input.value;
			const validator = validators[key];
			if (!validator) return true;
			return validator(value, input);
		});
	}

	function toggleButton() {
		const valid = isFormValid();
		submitButton.disabled = !valid;
		submitButton.classList.toggle("auth-submit--disabled", !valid);
	}

	// add listeners
	Object.entries(fields).forEach(([key, input]) => {
		if (!input) return;
		const eventName = input.type === "checkbox" ? "change" : "input";
		input.addEventListener(eventName, toggleButton);
	});

	form.addEventListener("submit", (e) => {
		if (!isFormValid()) {
			e.preventDefault();
			return;
		}

		// Sync native date input with display value before submit
		// Convert DD.MM.YYYY from display to YYYY-MM-DD for native input
		if (fields.birthdate && fields.birthdateNative) {
			const parsed = parseDisplayValue(fields.birthdate.value);
			if (parsed) {
				fields.birthdateNative.value = parsed;
			} else {
				// If display is empty or invalid, clear native input
				fields.birthdateNative.value = '';
			}
		}
	});

	// initial state
	toggleButton();
});
