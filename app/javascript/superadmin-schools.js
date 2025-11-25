document.addEventListener('DOMContentLoaded', () => {
	const modalApi = window.ModalUtils?.initModal({
		modalId: 'add-school-modal',
		triggerSelector: '.schools-page__add',
	});

	const deleteModalApi = window.ModalUtils?.initModal({
		modalId: 'delete-school-modal'
	});

	if (!modalApi) return;

	const modal = modalApi.modal;
	const titleEl = modal.querySelector('#school-modal-title');
	const primaryBtn = modal.querySelector('.schools-modal__primary');
	const nameInput = modal.querySelector('#school-name');
	const addressInput = modal.querySelector('#school-address');
	const headmasterInput = modal.querySelector('#school-headmaster');
	const requiredInputs = [nameInput, addressInput].filter(Boolean);

	const setPrimaryDisabled = (isDisabled) => {
		if (!primaryBtn) return;
		primaryBtn.disabled = isDisabled;
		primaryBtn.setAttribute('aria-disabled', isDisabled ? 'true' : 'false');
		primaryBtn.classList.toggle('is-disabled', isDisabled);
	};

	const isFormValid = () => requiredInputs
		.every((input) => input.value.trim().length >= 2);

	const validateForm = () => {
		const valid = isFormValid();
		setPrimaryDisabled(!valid);
		return valid;
	};

	const resetForm = () => {
		requiredInputs.forEach((input) => {
			input.value = '';
			input.setCustomValidity('');
		});
		if (headmasterInput) headmasterInput.value = '';
	};

	const setModalMode = (mode) => {
		if (!modal) return;
		modal.dataset.mode = mode;
		if (mode === 'add') {
			titleEl.textContent = 'Add school';
			primaryBtn.textContent = 'Add';
			resetForm();
		} else {
			titleEl.textContent = 'Edit school';
			primaryBtn.textContent = 'Save';
		}
		validateForm();
	};

	setModalMode('add');

	document.querySelectorAll('button[aria-label="Edit school"]').forEach((btn) => {
		btn.addEventListener('click', () => {
			const tr = btn.closest('tr');
			if (!tr) return;
			const cells = tr.querySelectorAll('td');
			const rowName = cells[0]?.textContent?.trim() || '';
			const rowAddress = cells[1]?.textContent?.trim() || '';
			const rowHeadmaster = cells[2]?.textContent?.trim() || '';

			if (nameInput) nameInput.value = rowName;
			if (addressInput) addressInput.value = rowAddress;
			if (headmasterInput) headmasterInput.value = rowHeadmaster;

			setModalMode('edit');
			modalApi.openModal();
		});
	});

	const addTrigger = document.querySelector('.schools-page__add');
	addTrigger?.addEventListener('click', () => {
		setModalMode('add');
	}, { capture: true });

	requiredInputs.forEach((input) => {
		input.addEventListener('input', () => {
			input.setCustomValidity('');
			validateForm();
		});
		input.addEventListener('blur', () => {
			if (!input.value.trim()) {
				input.setCustomValidity('This field is required.');
				input.reportValidity();
			}
		});
	});

	const form = document.getElementById('schools-form');
	form?.addEventListener('submit', (ev) => {
		if (!validateForm()) {
			ev.preventDefault();
			requiredInputs.find((input) => !input.value.trim())?.focus();
			return;
		}
		ev.preventDefault();
		modalApi.closeModal();
	});

	const deleteNameNode = document.querySelector('[data-school-delete-name]');
	const deleteButtons = document.querySelectorAll('button[aria-label="Delete school"]');
	deleteButtons.forEach((btn) => {
		btn.addEventListener('click', () => {
			const schoolName = btn.dataset.schoolName || 'this school';
			if (deleteNameNode) deleteNameNode.textContent = schoolName;
			deleteModalApi?.openModal();
		});
	});

	document.querySelector('[data-confirm-delete-school]')?.addEventListener('click', () => {
		deleteModalApi?.closeModal();
	});
});
