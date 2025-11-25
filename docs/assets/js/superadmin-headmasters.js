document.addEventListener('DOMContentLoaded', () => {
	const addForm = document.getElementById('add-headmaster-form');
	const editForm = document.getElementById('edit-headmaster-form');

	const addModalApi = window.ModalUtils?.initModal({
		modalId: 'add-headmaster-modal',
		triggerSelector: '.schools-page__add',
		onOpen: () => {
			addForm?.reset();
			addFormController?.validate();
		}
	});

	const editModalApi = window.ModalUtils?.initModal({
		modalId: 'edit-headmaster-modal'
	});

	const deactivateModalApi = window.ModalUtils?.initModal({
		modalId: 'deactivate-headmaster-modal'
	});

	const createFormController = (form, modalController) => {
		if (!form) return null;
		const submitBtn = form.querySelector('.schools-modal__primary');
		const requiredInputs = Array.from(form.querySelectorAll('[required]'));

		const setPrimaryDisabled = (isDisabled) => {
			if (!submitBtn) return;
			submitBtn.disabled = isDisabled;
			submitBtn.setAttribute('aria-disabled', isDisabled ? 'true' : 'false');
			submitBtn.classList.toggle('is-disabled', isDisabled);
		};

		const isFormValid = () => requiredInputs.every((input) => input.value.trim());
		const validate = () => {
			const valid = isFormValid();
			setPrimaryDisabled(!valid);
			return valid;
		};

		requiredInputs.forEach((input) => {
			input.addEventListener('input', () => {
				input.setCustomValidity('');
				validate();
			});
			input.addEventListener('blur', () => {
				if (!input.value.trim()) {
					input.setCustomValidity('This field is required.');
					input.reportValidity();
				}
			});
		});

		form.addEventListener('submit', (event) => {
			if (!validate()) {
				event.preventDefault();
				requiredInputs.find((input) => !input.value.trim())?.focus();
				return;
			}
			event.preventDefault();
			modalController?.closeModal?.();
		});

		validate();
		return { validate };
	};

	const addFormController = createFormController(addForm, addModalApi);
	const editFormController = createFormController(editForm, editModalApi);

	document.querySelectorAll('button[data-action="edit"]').forEach((button) => {
		button.addEventListener('click', () => {
			if (!editForm || !editFormController) return;
			const schoolSelect = editForm.querySelector('[name="school"]');
			const nameInput = editForm.querySelector('input[name="headmaster_name"]');
			const emailInput = editForm.querySelector('input[name="email"]');
			const phoneInput = editForm.querySelector('input[name="phone"]');

			if (schoolSelect) {
				schoolSelect.value = button.dataset.school || '';
			}
			if (nameInput) {
				nameInput.value = button.dataset.name || '';
			}
			if (emailInput) {
				emailInput.value = button.dataset.email || '';
			}
			if (phoneInput) {
				phoneInput.value = button.dataset.phone || '';
			}
			editFormController.validate();
			editModalApi?.openModal?.();
		});
	});

	const deactivateNameNode = document.querySelector('[data-deactivate-name]');
	document.querySelectorAll('button[data-action="deactivate"]').forEach((button) => {
		button.addEventListener('click', () => {
			if (deactivateNameNode) {
				deactivateNameNode.textContent = button.dataset.headmaster || 'this headmaster';
			}
			deactivateModalApi?.openModal?.();
		});
	});

	document.querySelector('[data-confirm-deactivate]')?.addEventListener('click', () => {
		deactivateModalApi?.closeModal?.();
	});

	document.addEventListener('click', (event) => {
		document.querySelectorAll('.headmasters-menu[open]').forEach((menu) => {
			if (!menu.contains(event.target)) {
				menu.removeAttribute('open');
			}
		});
	});
});
