document.addEventListener('DOMContentLoaded', () => {
	let modalController;

	const modal = document.getElementById('edit-school-modal');
	const uploadBtn = modal?.querySelector('.school-edit-upload__button');
	const fileInput = modal?.querySelector('.school-edit-upload__input');
	const previewImage = modal?.querySelector('.school-edit-upload__preview');
	const defaultPreviewSrc = previewImage?.dataset.defaultSrc || previewImage?.src || '';
	let previewObjectUrl = null;
	const form = modal?.querySelector('#edit-school-form');
	const submitButton = form?.querySelector('.schools-modal__primary');
	const errorNodes = {};
	let recomputeButtonState = () => {};

	form?.querySelectorAll('[data-error-for]').forEach((node) => {
		errorNodes[node.dataset.errorFor] = node;
	});

	const resetPreview = () => {
		if (!previewImage) return;
		if (previewObjectUrl) {
			URL.revokeObjectURL(previewObjectUrl);
			previewObjectUrl = null;
		}
		previewImage.src = defaultPreviewSrc;
		if (fileInput) {
			fileInput.value = '';
		}
	};

	const handleLogoChange = () => {
		if (!fileInput || !previewImage) return;
		const [file] = fileInput.files || [];
		if (!file) return;
		if (previewObjectUrl) {
			URL.revokeObjectURL(previewObjectUrl);
		}
		previewObjectUrl = URL.createObjectURL(file);
		previewImage.src = previewObjectUrl;
	};

	if (form && submitButton) {
		const validators = {
			'school-name-input': {
				input: form.querySelector('#school-name-input'),
				validate: (value) => value.trim().length >= 3,
				message: 'School name must be at least 3 characters.',
			},
			'school-address-input': {
				input: form.querySelector('#school-address-input'),
				validate: (value) => value.trim().length >= 5,
				message: 'Address must be at least 5 characters.',
			},
			'school-phone-input': {
				input: form.querySelector('#school-phone-input'),
				validate: (value) => /^\+?[0-9\s-]{8,}$/.test(value.trim()),
				message: 'Provide a valid phone number.',
			},
			'school-email-input': {
				input: form.querySelector('#school-email-input'),
				validate: (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim()),
				message: 'Provide a valid email.',
			},
			'school-headmaster-input': {
				input: form.querySelector('#school-headmaster-input'),
				validate: (value) => value.trim().length >= 3,
				message: 'Headmaster name must be at least 3 characters.',
			},
			'school-deputy-input': {
				input: form.querySelector('#school-deputy-input'),
				validate: () => true,
				message: '',
			},
		};

		const showFieldError = (inputId, message) => {
			const input = form.querySelector(`#${inputId}`);
			if (!input) return;
			const errorNode = errorNodes[inputId];
			if (message) {
				input.classList.add('is-invalid');
				if (errorNode) errorNode.textContent = message;
			} else {
				input.classList.remove('is-invalid');
				if (errorNode) errorNode.textContent = '';
			}
		};

		const validateField = (config) => {
			if (!config?.input) return true;
			const isValid = config.validate(config.input.value || '');
			showFieldError(config.input.id, isValid ? '' : config.message);
			config.input.setCustomValidity(isValid ? '' : config.message);
			return isValid;
		};

		const toggleButtonState = (isEnabled) => {
			if (!submitButton) return;
			submitButton.disabled = !isEnabled;
			submitButton.classList.toggle('is-disabled', !isEnabled);
		};

		recomputeButtonState = () => {
			const isValid = Object.values(validators).every((config) => config?.input && config.validate(config.input.value || ''));
			toggleButtonState(isValid);
		};

		Object.values(validators).forEach((config) => {
			config.input?.addEventListener('input', () => {
				validateField(config);
				recomputeButtonState();
			});
		});

		form.addEventListener('submit', (event) => {
			event.preventDefault();
			let firstInvalid = null;
			Object.values(validators).forEach((config) => {
				if (!validateField(config) && !firstInvalid) {
					firstInvalid = config.input;
				}
			});

			recomputeButtonState();

			if (firstInvalid) {
				firstInvalid.reportValidity();
				return;
			}

			modalController?.closeModal();
		});

		recomputeButtonState();
	}

	const handleModalOpen = () => {
		resetPreview();
		recomputeButtonState();
	};

	modalController = window.ModalUtils?.initModal({
		modalId: 'edit-school-modal',
		triggerSelector: '.js-open-school-modal',
		onOpen: handleModalOpen,
	});

	if (!modalController) return;

	resetPreview();
	recomputeButtonState();

	uploadBtn?.addEventListener('click', () => fileInput?.click());
	fileInput?.addEventListener('change', handleLogoChange);
});
