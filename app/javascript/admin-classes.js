const initAddClassModal = () => {
	const form = document.querySelector('#add-class-modal [data-teaching-staff-form]');
	window.ModalUtils?.initModal({
		modalId: 'add-class-modal',
		triggerSelector: '.js-open-add-class',
		onClose: () => {
			form?.reset();
			form?.resetTeachingStaffSelector?.();
		}
	});
};

const initEditClassModal = () => {
	window.ModalUtils?.initModal({
		modalId: 'edit-class-modal',
		triggerSelector: '[data-edit-class]'
	});
};

const initArchiveYearModal = () => {
	const controller = window.ModalUtils?.initModal({
		modalId: 'archive-year-modal',
		triggerSelector: '.archive-year-btn'
	});

	const confirmButton = document.querySelector('.archive-year-modal__confirm');
	confirmButton?.addEventListener('click', () => {
		// Placeholder for archive action
		controller?.closeModal?.();
	});
};

const CLASS_NUMBER_PATTERN = /^[1-9][0-9]?[A-Za-z]$/;

const initTeachingStaffSelectors = () => {
	const forms = document.querySelectorAll('[data-teaching-staff-form]');

	const createHiddenInput = (name, value) => {
		const input = document.createElement('input');
		input.type = 'hidden';
		input.name = name;
		input.value = value;
		return input;
	};

	forms.forEach((form) => {
		const select = form.querySelector('[data-teaching-staff-select]');
		const selectWrapper = select?.closest('[data-teaching-staff-select-wrapper]');
		const trigger = selectWrapper?.querySelector('[data-teaching-staff-trigger]');
		const dropdown = selectWrapper?.querySelector('[data-teaching-staff-dropdown]');
		const optionsContainer = selectWrapper?.querySelector('[data-teaching-staff-options]');
		const summary = selectWrapper?.querySelector('[data-selected-summary]');
		const chipsContainer = form.querySelector('[data-teaching-staff-chips]');
		if (!select || !chipsContainer || !selectWrapper || !trigger || !dropdown || !optionsContainer || !summary) return;

		const modal = form.closest('.schools-modal');
		const formMode = modal?.id === 'add-class-modal' ? 'add' : modal?.id === 'edit-class-modal' ? 'edit' : null;
		const requiresValidation = Boolean(formMode);
		const isAddClassForm = formMode === 'add';
		const isEditClassForm = formMode === 'edit';
		const hiddenName = select.dataset.chipInputName || `${select.name || 'teaching_staff'}[]`;
		const selectedValues = new Set();
		const initialChipsMarkup = chipsContainer.innerHTML;
		const defaultSummary = trigger.dataset.defaultLabel || 'Select options';
		const errors = {
			classNumber: form.querySelector('[data-error="class_number"]'),
			teachingStaff: form.querySelector('[data-error="teaching_staff"]')
		};
		const touched = {
			classNumber: false,
			teachingStaff: false
		};

		const createRemoveButton = (value) => {
			const button = document.createElement('button');
			button.type = 'button';
			button.textContent = '×';
			button.setAttribute('aria-label', `Remove ${value}`);
			button.dataset.removeChip = '';
			return button;
		};

		// form-level controls
		const submitBtn = form.querySelector('button[type="submit"]');
		const classNumberInput = form.querySelector('[name="class_number"]');
		const setErrorMessage = (element, message = '') => {
			if (!element) return;
			element.textContent = message;
			element.hidden = !message;
		};

		const resetValidationState = () => {
			if (!requiresValidation) return;
			touched.classNumber = false;
			touched.teachingStaff = false;
			setErrorMessage(errors.classNumber, '');
			setErrorMessage(errors.teachingStaff, '');
			classNumberInput?.classList.remove('is-invalid');
			selectWrapper.classList.remove('has-error');
		};

		// make sure submit is disabled by default to avoid race conditions
		if (submitBtn) {
			submitBtn.disabled = true;
			submitBtn.setAttribute('aria-disabled', 'true');
			submitBtn.classList.add('is-disabled');
		}

		const updateFormState = () => {
			const hasClassNumber = classNumberInput && classNumberInput.value.trim() !== '';
			const hasTeachingStaff = selectedValues.size > 0;
			if (submitBtn) {
				submitBtn.disabled = !(hasClassNumber && hasTeachingStaff);
				// keep an accessible hint
				submitBtn.setAttribute('aria-disabled', submitBtn.disabled ? 'true' : 'false');
				submitBtn.classList.toggle('is-disabled', submitBtn.disabled);
			}
			if (requiresValidation) {
				validateFields();
			}
		};

		const getClassNumberValidation = () => {
			if (!classNumberInput) return { valid: true, message: '' };
			const value = classNumberInput.value.trim();
			if (!requiresValidation) return { valid: Boolean(value), message: '' };
			if (!value) {
				return { valid: false, message: '' };
			}
			if (classNumberInput.tagName === 'INPUT' && !CLASS_NUMBER_PATTERN.test(value)) {
				return { valid: false, message: 'Use the format like "4B".' };
			}
			return { valid: true, message: '' };
		};

		const getTeachingStaffValidation = () => {
			if (!requiresValidation) {
				return { valid: selectedValues.size > 0, message: '' };
			}
			if (selectedValues.size === 0) {
				return { valid: false, message: 'Select at least one teacher.' };
			}
			return { valid: true, message: '' };
		};

		const applyValidationStyles = (field, { valid, message }, force = false) => {
			if (!requiresValidation) return;
			const shouldDisplay = force || touched[field];
			if (field === 'classNumber' && classNumberInput) {
				if (shouldDisplay) {
					setErrorMessage(errors.classNumber, message);
					classNumberInput.classList.toggle('is-invalid', !valid);
				} else {
					setErrorMessage(errors.classNumber, '');
					classNumberInput.classList.remove('is-invalid');
				}
			}
			if (field === 'teachingStaff' && selectWrapper) {
				if (shouldDisplay) {
					setErrorMessage(errors.teachingStaff, message);
					selectWrapper.classList.toggle('has-error', !valid);
				} else {
					setErrorMessage(errors.teachingStaff, '');
					selectWrapper.classList.remove('has-error');
				}
			}
		};

		const validateFields = (force = false) => {
			const classValidation = getClassNumberValidation();
			const teachingStaffValidation = getTeachingStaffValidation();
			applyValidationStyles('classNumber', classValidation, force);
			applyValidationStyles('teachingStaff', teachingStaffValidation, force);
			return { classValidation, teachingStaffValidation };
		};

		const findOption = (value) => Array.from(select.options).find((option) => option.value === value);

		const findOptionButton = (value) => Array.from(optionsContainer.querySelectorAll('[data-option-value]'))
			.find((optionButton) => optionButton.dataset.optionValue === value);

		const updateSummary = () => {
			const count = selectedValues.size;
			summary.textContent = count ? `${count} selected` : defaultSummary;
		};

		const toggleDropdown = (forceState) => {
			const shouldOpen = typeof forceState === 'boolean' ? forceState : dropdown.hasAttribute('hidden');
			if (shouldOpen) {
				dropdown.hidden = false;
				selectWrapper.classList.add('is-open');
				trigger.setAttribute('aria-expanded', 'true');
			} else {
				dropdown.hidden = true;
				selectWrapper.classList.remove('is-open');
				trigger.setAttribute('aria-expanded', 'false');
			}
		};

		trigger.addEventListener('click', () => {
			toggleDropdown();
		});

		document.addEventListener('click', (event) => {
			if (!selectWrapper.contains(event.target)) {
				toggleDropdown(false);
			}
		});

		const handleEscape = (event) => {
			if (event.key === 'Escape') {
				toggleDropdown(false);
				trigger.focus();
			}
		};

		trigger.addEventListener('keydown', handleEscape);
		dropdown.addEventListener('keydown', handleEscape);

		const buildOptions = () => {
			optionsContainer.innerHTML = '';
			Array.from(select.options).forEach((option) => {
				if (!option.value) return;
				const button = document.createElement('button');
				button.type = 'button';
				button.className = 'teaching-staff-select__option';
				button.dataset.optionValue = option.value;
				button.setAttribute('role', 'option');
				button.textContent = option.textContent.trim();
				button.classList.toggle('is-selected', selectedValues.has(option.value));
				button.setAttribute('aria-selected', selectedValues.has(option.value) ? 'true' : 'false');

			button.addEventListener('click', () => {
				if (selectedValues.has(option.value)) {
					removeChipByValue(option.value);
				} else {
					addChip(option.value, option.textContent.trim());
				}
					updateSummary();
				});

				optionsContainer.appendChild(button);
			});
		};

		const setOptionState = (value, isSelected) => {
			const option = findOption(value);
			if (option) {
				option.dataset.selected = isSelected ? 'true' : 'false';
			}

			const optionButton = findOptionButton(value);
			if (optionButton) {
				optionButton.classList.toggle('is-selected', isSelected);
				optionButton.setAttribute('aria-selected', isSelected ? 'true' : 'false');
			}
		};

		const addChip = (value, labelText = value) => {
			if (!value || selectedValues.has(value)) return;
			selectedValues.add(value);

			const chip = document.createElement('span');
			chip.className = 'teaching-staff-chips__item';
			chip.dataset.teachingStaffChip = '';
			chip.dataset.value = value;
			const label = document.createElement('span');
			label.className = 'teaching-staff-chips__label';
			label.textContent = labelText;
			chip.append(label);
			chip.append(createRemoveButton(value));
			chip.append(createHiddenInput(hiddenName, value));
			chipsContainer.appendChild(chip);

			setOptionState(value, true);
			updateSummary();
			updateFormState();
			if (isAddClassForm) {
				touched.teachingStaff = true;
				validateFields();
			}
		};

		const removeChip = (chip) => {
			if (!chip) return;
			const value = chip.dataset.value;
			if (value) {
				selectedValues.delete(value);
				setOptionState(value, false);
			}
			chip.remove();
			updateSummary();
			updateFormState();
			if (isAddClassForm) {
				touched.teachingStaff = true;
				validateFields();
			}
		};

		const removeChipByValue = (value) => {
			const chip = Array.from(chipsContainer.querySelectorAll('[data-teaching-staff-chip]'))
				.find((item) => item.dataset.value === value);
			if (chip) {
				removeChip(chip);
			}
		};

		chipsContainer.addEventListener('click', (event) => {
			const removeButton = event.target.closest('[data-remove-chip]');
			if (!removeButton) return;
			const chip = removeButton.closest('[data-teaching-staff-chip]');
			removeChip(chip);
		});

		const hydrateChips = () => {
			chipsContainer.querySelectorAll('[data-teaching-staff-chip]').forEach((chip) => {
				const value = chip.dataset.value?.trim();
				if (!value) return;
				selectedValues.add(value);
				if (!chip.querySelector('.teaching-staff-chips__label')) {
					const label = document.createElement('span');
					label.className = 'teaching-staff-chips__label';
					label.textContent = value;
					chip.insertBefore(label, chip.firstChild);
				}
				if (!chip.querySelector('input[type="hidden"]')) {
					chip.append(createHiddenInput(hiddenName, value));
				}
				if (!chip.querySelector('[data-remove-chip]')) {
					chip.append(createRemoveButton(value));
				}
				setOptionState(value, true);
			});
		};

		const resetSelector = () => {
			selectedValues.clear();
			buildOptions();
			chipsContainer.innerHTML = initialChipsMarkup;
			hydrateChips();
			dropdown.hidden = true;
			selectWrapper.classList.remove('is-open');
			trigger.setAttribute('aria-expanded', 'false');
			updateSummary();
			updateFormState();
			resetValidationState();
		};

		buildOptions();
		hydrateChips();
		updateSummary();
		// initial form state based on prefilled values
		updateFormState();

		if (classNumberInput) {
			const classNumberEvent = classNumberInput.tagName === 'SELECT' ? 'change' : 'input';
			classNumberInput.addEventListener(classNumberEvent, () => {
				updateFormState();
				if (requiresValidation) {
					touched.classNumber = true;
					validateFields();
				}
			});
			classNumberInput.addEventListener('blur', () => {
				if (!requiresValidation) return;
				touched.classNumber = true;
				validateFields();
			});
		}

		if (requiresValidation) {
			form.addEventListener('submit', (event) => {
				touched.classNumber = true;
				touched.teachingStaff = true;
				const { classValidation, teachingStaffValidation } = validateFields(true);
				const formIsValid = classValidation.valid && teachingStaffValidation.valid;
				if (!formIsValid) {
					event.preventDefault();
					if (!classValidation.valid && classNumberInput) {
						classNumberInput.focus();
					} else if (!teachingStaffValidation.valid) {
						trigger.focus();
					}
				}
			});
		}

		form.resetTeachingStaffSelector = resetSelector;

		// Ensure modal triggers reset/disable the submit button when opening
		const addTriggers = document.querySelectorAll('.js-open-add-class');
		if (isAddClassForm && addTriggers.length) {
			addTriggers.forEach((t) => t.addEventListener('click', () => {
				resetSelector();
				updateFormState();
				if (submitBtn) {
					submitBtn.disabled = true;
					submitBtn.setAttribute('aria-disabled', 'true');
					submitBtn.classList.add('is-disabled');
				}
			}));
		}

		if (isEditClassForm) {
			const editTriggers = document.querySelectorAll('[data-edit-class]');
			if (editTriggers.length) {
				editTriggers.forEach((t) => t.addEventListener('click', () => {
					resetValidationState();
					updateFormState();
					if (submitBtn) {
						submitBtn.setAttribute('aria-disabled', submitBtn.disabled ? 'true' : 'false');
						submitBtn.classList.toggle('is-disabled', submitBtn.disabled);
					}
				}));
			}
		}
	});
};

document.addEventListener('DOMContentLoaded', () => {
	initAddClassModal();
	initEditClassModal();
	initArchiveYearModal();
	initTeachingStaffSelectors();

	const makeNavigable = (selector, defaultHref = '') => {
		document.querySelectorAll(selector).forEach((element) => {
			const href = element.dataset.href || defaultHref;
			if (!href) return;

			if (!element.hasAttribute('tabindex')) element.setAttribute('tabindex', '0');
			element.style.cursor = 'pointer';

			const navigateTo = () => {
				window.location.href = href;
			};

			element.addEventListener('click', (e) => {
				if (e.target.closest('[data-edit-class]')) return;
				navigateTo();
			});
			element.addEventListener('keydown', (e) => {
				if (e.key === 'Enter' || e.key === ' ') {
					e.preventDefault();
					navigateTo();
				}
			});
		});
	};

	makeNavigable('.class-year-card[data-href]');
	makeNavigable('.class-result', 'quiz-results.html');
	makeNavigable('.school-profile-hero__stat-card[data-href]');
});
