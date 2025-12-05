document.addEventListener('DOMContentLoaded', () => {
	const pickers = document.querySelectorAll('.activity-date-picker');
	const pickersByRole = {};
	const copyButtons = document.querySelectorAll('[data-copy-value], [data-copy-json]');

	const formatDate = (value) => {
		if (!value) return '';
		const date = new Date(value);
		if (Number.isNaN(date.getTime())) return '';
		const pad = (num) => String(num).padStart(2, '0');
		return `${pad(date.getDate())}.${pad(date.getMonth() + 1)}.${date.getFullYear()} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
	};

	const parseDisplayValue = (value) => {
		const trimmed = value.trim();
		if (!trimmed) return '';
		const match = trimmed.match(/^(\d{2})\.(\d{2})\.(\d{4})(?: (\d{2}):(\d{2}))?$/);
		if (!match) return '';
		const [, day, month, year, hour = '00', minute = '00'] = match;
		const isoValue = `${year}-${month}-${day}T${hour}:${minute}`;
		const date = new Date(isoValue);
		if (Number.isNaN(date.getTime())) return '';
		return isoValue;
	};

	const buildDefaultIso = () => {
		const now = new Date();
		now.setSeconds(0, 0);
		const pad = (num) => String(num).padStart(2, '0');
		return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}T00:00`;
	};

	const resetError = (entry) => {
		if (!entry) return;
		entry.nativeInput.setCustomValidity('');
		entry.picker.classList.remove('activity-date-picker--error');
	};

	const setError = (entry, message) => {
		if (!entry) return;
		entry.nativeInput.setCustomValidity(message);
		entry.picker.classList.add('activity-date-picker--error');
	};

	const validateRange = () => {
		const fromEntry = pickersByRole.from;
		const toEntry = pickersByRole.to;
		resetError(fromEntry);
		resetError(toEntry);

		const fromValue = fromEntry?.nativeInput.value;
		const toValue = toEntry?.nativeInput.value;

		if (!fromValue || !toValue) return;

		if (fromValue > toValue) {
			const message = 'Start date must be earlier than end date';
			setError(fromEntry, message);
			setError(toEntry, message);
		}
	};

	const syncDisplay = (entry) => {
		if (!entry) return;
		entry.displayInput.value = formatDate(entry.nativeInput.value);
		validateRange();
	};

	pickers.forEach((picker) => {
		const nativeInput = picker.querySelector('.activity-date-picker__native');
		const displayInput = picker.querySelector('.activity-date-picker__display');
		const clearBtn = picker.querySelector('.activity-date-picker__clear');
		const calendarBtn = picker.querySelector('.activity-date-picker__calendar');

		if (!nativeInput || !displayInput) return;

		const entry = { picker, nativeInput, displayInput };
		const role = picker.dataset.dateRole;
		if (role) {
			pickersByRole[role] = entry;
		}

		nativeInput.addEventListener('change', () => syncDisplay(entry));

		displayInput.addEventListener('input', () => {
			if (displayInput.value.trim() === '') {
				nativeInput.value = '';
				validateRange();
			}
		});

		displayInput.addEventListener('blur', () => {
			const parsed = parseDisplayValue(displayInput.value);
			if (parsed) {
				nativeInput.value = parsed;
				syncDisplay(entry);
			} else if (displayInput.value.trim() === '') {
				nativeInput.value = '';
				validateRange();
			} else if (nativeInput.value) {
				displayInput.value = formatDate(nativeInput.value);
			} else {
				displayInput.value = '';
			}
		});

		if (clearBtn) {
			clearBtn.addEventListener('click', () => {
				nativeInput.value = '';
				displayInput.value = '';
				validateRange();
				displayInput.focus();
			});
		}

		if (calendarBtn) {
			calendarBtn.addEventListener('click', () => {
				if (!nativeInput.value) {
					const parsed = parseDisplayValue(displayInput.value);
					nativeInput.value = parsed || buildDefaultIso();
				}

				nativeInput.focus({ preventScroll: true });
				if (typeof nativeInput.showPicker === 'function') {
					nativeInput.showPicker();
				} else {
					nativeInput.focus();
				}
			});
		}

		syncDisplay(entry);
	});

	const copyToClipboard = async (text) => {
		if (!text) return;
		if (navigator.clipboard && typeof navigator.clipboard.writeText === 'function') {
			return navigator.clipboard.writeText(text);
		}

		const textarea = document.createElement('textarea');
		textarea.value = text;
		textarea.setAttribute('readonly', '');
		textarea.style.position = 'absolute';
		textarea.style.left = '-9999px';
		document.body.appendChild(textarea);
		textarea.select();
		try {
			document.execCommand('copy');
		} finally {
			document.body.removeChild(textarea);
		}
	};

	const successTimers = new WeakMap();

	const getCopyValue = (button) => {
		if (button.dataset.copyValue) {
			return button.dataset.copyValue;
		}
		if (button.hasAttribute('data-copy-json')) {
			const container = button.closest('.activity-entry__json');
			const pre = container?.querySelector('pre');
			return pre ? pre.textContent.trim() : '';
		}
		return '';
	};

	copyButtons.forEach((button) => {
		button.addEventListener('click', async () => {
			const value = getCopyValue(button);
			if (!value) return;
			try {
				await copyToClipboard(value);
				button.classList.add('is-success');
				const previousTimer = successTimers.get(button);
				if (previousTimer) clearTimeout(previousTimer);
				const timer = setTimeout(() => {
					button.classList.remove('is-success');
					successTimers.delete(button);
				}, 1200);
				successTimers.set(button, timer);
			} catch (err) {
				console.error('Copy failed', err);
			}
		});
	});
});
