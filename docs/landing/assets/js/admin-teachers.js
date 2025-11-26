document.addEventListener('DOMContentLoaded', () => {
	const editModalController = window.ModalUtils?.initModal({
		modalId: 'edit-teacher-modal',
	});

	const approvalModalController = window.ModalUtils?.initModal({
		modalId: 'teachers-approve-modal',
	});
	const rejectModalController = window.ModalUtils?.initModal({
		modalId: 'teachers-reject-modal',
	});
	const deleteModalController = window.ModalUtils?.initModal({
		modalId: 'teachers-delete-modal',
	});
	const pupilDetailsController = window.ModalUtils?.initModal({
		modalId: 'pupil-details-modal',
	});

	const nameInput = document.getElementById('teacher-name');
	const birthInput = document.getElementById('teacher-birth');
	const emailInput = document.getElementById('teacher-email');
	const phoneInput = document.getElementById('teacher-phone');
	const subjectsInput = document.getElementById('teacher-subjects');
	const editButtons = document.querySelectorAll('.js-edit-pupil, .js-edit-teacher');
	const approveButtons = document.querySelectorAll('.js-approve-pupil, .js-approve-teacher');
	const approveNameNode = document.querySelector('.teachers-approve-modal__name');
	const rejectButtons = document.querySelectorAll('.js-reject-pupil, .js-reject-teacher');
	const rejectNameNode = document.querySelector('.teachers-reject-modal__name');
	const deleteButtons = document.querySelectorAll('.js-delete-pupil, .js-delete-teacher');
	const deleteNameNode = document.querySelector('.teachers-delete-modal__name');

	const editForm = document.getElementById('teacher-edit-form');
	const submitButton = editForm?.querySelector('.schools-modal__primary');
	const errorNodes = {};
	document.querySelectorAll('[data-error-for]').forEach((node) => {
		errorNodes[node.dataset.errorFor] = node;
	});
	const pupilRows = document.querySelectorAll('.js-pupil-row');
	const detailsNodes = {
		name: document.querySelector('.pupil-details-modal__name'),
		birth: document.querySelector('.pupil-details-modal__birth'),
		email: document.querySelector('.pupil-details-modal__email'),
		phone: document.querySelector('.pupil-details-modal__phone'),
		subjects: document.querySelector('.pupil-details-modal__subjects'),
		address: document.querySelector('.pupil-details-modal__address'),
		parent: document.querySelector('.pupil-details-modal__parent'),
	};

	const validators = {
		'teacher-name': (value) => (value.trim().length >= 3 ? '' : 'Name must be at least 3 characters'),
		'teacher-birth': (value) => (/^\d{2}\.\d{2}\.\d{4}$/.test(value.trim()) ? '' : 'Use DD.MM.YYYY'),
		'teacher-email': (value) => (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim()) ? '' : 'Provide a valid email'),
		'teacher-phone': (value) => (value.trim().length >= 8 ? '' : 'Phone must be at least 8 digits'),
		'teacher-subjects': (value) => (value.trim().length >= 3 ? '' : 'Subjects must be at least 3 characters'),
	};

	const showError = (inputId, message) => {
		const input = document.getElementById(inputId);
		const node = errorNodes[inputId];
		if (!input) return;
		if (message) {
			input.classList.add('is-invalid');
			if (node) node.textContent = message;
		} else {
			input.classList.remove('is-invalid');
			if (node) node.textContent = '';
		}
	};

	const validateField = (inputId) => {
		const input = document.getElementById(inputId);
		if (!input) return true;
		const validator = validators[inputId];
		const message = validator ? validator(input.value) : '';
		showError(inputId, message);
		return !message;
	};

	const computeIsValid = () =>
		Object.keys(validators).every((inputId) => {
			const input = document.getElementById(inputId);
			if (!input) return true;
			const validator = validators[inputId];
			const message = validator ? validator(input.value) : '';
			return !message;
		});

	const toggleSubmitState = (isEnabled) => {
		if (!submitButton) return;
		submitButton.disabled = !isEnabled;
		submitButton.classList.toggle('is-disabled', !isEnabled);
	};

	const fillForm = (button) => {
		if (!button || !editModalController) return;
		nameInput.value = button.dataset.name || '';
		birthInput.value = button.dataset.birth || '';
		emailInput.value = button.dataset.email || '';
		phoneInput.value = button.dataset.phone || '';
		subjectsInput.value = button.dataset.subjects || '';
		Object.keys(validators).forEach((fieldId) => showError(fieldId, ''));
		toggleSubmitState(computeIsValid());
		editModalController.openModal();
	};

	editButtons.forEach((button) => {
		button.addEventListener('click', () => fillForm(button));
	});

	if (editForm) {
		Object.keys(validators).forEach((fieldId) => {
			const input = document.getElementById(fieldId);
			input?.addEventListener('input', () => {
				validateField(fieldId);
				toggleSubmitState(computeIsValid());
			});
		});

		editForm.addEventListener('submit', (event) => {
			event.preventDefault();
			const isValid = Object.keys(validators).every((fieldId) => validateField(fieldId));
			toggleSubmitState(isValid);
			if (isValid) {
				editModalController?.closeModal();
			} else {
				const invalidInput = Object.keys(validators)
					.map((fieldId) => document.getElementById(fieldId))
					.find((input) => input?.classList.contains('is-invalid'));
				invalidInput?.reportValidity();
			}
		});

		toggleSubmitState(false);
	}

	approveButtons.forEach((button) => {
		button.addEventListener('click', () => {
			if (!approvalModalController) return;
			if (approveNameNode) {
				approveNameNode.textContent = button.dataset.pupil || button.dataset.teacher || 'this pupil';
			}
			approvalModalController.openModal();
		});
	});

	rejectButtons.forEach((button) => {
		button.addEventListener('click', () => {
			if (!rejectModalController) return;
			if (rejectNameNode) {
				rejectNameNode.textContent = button.dataset.pupil || button.dataset.teacher || 'this pupil';
			}
			rejectModalController.openModal();
		});
	});

	deleteButtons.forEach((button) => {
		button.addEventListener('click', () => {
			if (!deleteModalController) return;
			if (deleteNameNode) {
				deleteNameNode.textContent = button.dataset.pupil || button.dataset.teacher || 'this pupil';
			}
			deleteModalController.openModal();
		});
	});

	pupilRows.forEach((row) => {
		row.addEventListener('click', (event) => {
			if (event.target.closest('.teachers-actions')) return;
			if (!pupilDetailsController) return;
			Object.entries(detailsNodes).forEach(([key, node]) => {
				if (!node) return;
				const value = row.dataset[`pupil${key.charAt(0).toUpperCase()}${key.slice(1)}`] || row.dataset[`pupil-${key}`];
				if (value) {
					node.textContent = value;
				}
			});
			pupilDetailsController.openModal();
		});
	});
});
