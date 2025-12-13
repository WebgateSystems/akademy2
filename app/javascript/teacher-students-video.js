document.addEventListener('DOMContentLoaded', () => {
	const editModalController = window.ModalUtils?.initModal({
		modalId: 'video-edit-modal',
	});
	const approveModalController = window.ModalUtils?.initModal({
		modalId: 'video-approve-modal',
	});
	const rejectModalController = window.ModalUtils?.initModal({
		modalId: 'video-reject-modal',
	});
	const deleteModalController = window.ModalUtils?.initModal({
		modalId: 'video-delete-modal',
	});
	const playerIframe = document.getElementById('video-player-frame');
	const videoPlayerController = window.ModalUtils?.initModal({
		modalId: 'video-player-modal',
		onClose: () => {
			if (playerIframe) {
				playerIframe.src = '';
			}
		},
	});

	const titleInput = document.getElementById('video-title');
	const topicInput = document.getElementById('video-topic');
	const descriptionInput = document.getElementById('video-description');
	const authorInput = document.getElementById('video-author');
	const urlInput = document.getElementById('video-url');
	const editForm = document.getElementById('video-edit-form');

	const editButtons = document.querySelectorAll('.js-edit-video');
	const approveButtons = document.querySelectorAll('.js-approve-video');
	const rejectButtons = document.querySelectorAll('.js-reject-video');
	const deleteButtons = document.querySelectorAll('.js-delete-video');
	const videoButtons = document.querySelectorAll('.js-open-video');

	const approveStudentNode = document.querySelector('.video-approve-modal__student');
	const approveVideoNode = document.querySelector('.video-approve-modal__video');
	const rejectStudentNode = document.querySelector('.video-reject-modal__student');
	const rejectVideoNode = document.querySelector('.video-reject-modal__video');
	const deleteStudentNode = document.querySelector('.video-delete-modal__student');
	const deleteVideoNode = document.querySelector('.video-delete-modal__video');
	const videoTitleNode = document.querySelector('.video-player-modal__title');
	let updateSubmitState = () => {};

	const getEmbedUrl = (url) => {
		if (!url) return '';
		if (url.includes('embed')) return url;
		const idMatch = url.match(/(?:v=|youtu\.be\/|embed\/)([a-zA-Z0-9_-]{11})/);
		if (idMatch && idMatch[1]) {
			return `https://www.youtube.com/embed/${idMatch[1]}`;
		}
		return url;
	};

	const fillEditForm = (button) => {
		if (!button || !editModalController) return;
		titleInput.value = button.dataset.title || '';
		topicInput.value = button.dataset.topic || '';
		descriptionInput.value = button.dataset.description || '';
		authorInput.value = button.dataset.author || '';
		urlInput.value = button.dataset.url || '';
		editModalController.openModal();
		updateSubmitState();
	};

	editButtons.forEach((button) => {
		button.addEventListener('click', () => fillEditForm(button));
	});

	approveButtons.forEach((button) => {
		button.addEventListener('click', () => {
			if (!approveModalController) return;
			if (approveStudentNode) {
				approveStudentNode.textContent = button.dataset.student || 'this student';
			}
			if (approveVideoNode) {
				approveVideoNode.textContent = button.dataset.video || 'this video';
			}
			approveModalController.openModal();
		});
	});

	rejectButtons.forEach((button) => {
		button.addEventListener('click', () => {
			if (!rejectModalController) return;
			if (rejectStudentNode) {
				rejectStudentNode.textContent = button.dataset.student || 'this student';
			}
			if (rejectVideoNode) {
				rejectVideoNode.textContent = button.dataset.video || 'this video';
			}
			rejectModalController.openModal();
		});
	});

	deleteButtons.forEach((button) => {
		button.addEventListener('click', () => {
			if (!deleteModalController) return;
			if (deleteStudentNode) {
				deleteStudentNode.textContent = button.dataset.student || 'this student';
			}
			if (deleteVideoNode) {
				deleteVideoNode.textContent = button.dataset.video || 'this video';
			}
			deleteModalController.openModal();
		});
	});

	videoButtons.forEach((button) => {
		button.addEventListener('click', () => {
			if (!videoPlayerController || !playerIframe) return;
			const embedUrl = getEmbedUrl(button.dataset.videoUrl);
			if (videoTitleNode) {
				videoTitleNode.textContent = button.dataset.videoTitle || 'Student video';
			}
			playerIframe.src = embedUrl;
			videoPlayerController.openModal();
		});
	});

	if (editForm) {
		const submitButton = editForm.querySelector('.schools-modal__primary');
		const errorNodes = {};
		document.querySelectorAll('[data-error-for]').forEach((node) => {
			errorNodes[node.dataset.errorFor] = node;
		});

		const validators = {
			'video-title': {
				input: titleInput,
				validate: (value) => value.trim().length >= 3,
				message: 'Title must be at least 3 characters.',
			},
			'video-topic': {
				input: topicInput,
				validate: (value) => value.trim().length >= 3,
				message: 'Topic must be at least 3 characters.',
			},
			'video-description': {
				input: descriptionInput,
				validate: (value) => value.trim().length >= 10,
				message: 'Description must be at least 10 characters.',
			},
			'video-author': {
				input: authorInput,
				validate: (value) => value.trim().length >= 3,
				message: 'Author is required.',
			},
			'video-url': {
				input: urlInput,
				validate: (value) => {
					try {
						const parsed = new URL(value);
						return parsed.protocol.startsWith('http');
					} catch {
						return false;
					}
				},
				message: 'Provide a valid link.',
			},
		};

		const showFieldError = (inputId, message) => {
			const node = errorNodes[inputId];
			const input = document.getElementById(inputId);
			if (!input) return false;
			if (message) {
				input.classList.add('is-invalid');
				if (node) node.textContent = message;
			} else {
				input.classList.remove('is-invalid');
				if (node) node.textContent = '';
			}
			return !message;
		};

		const validateField = (config) => {
			if (!config?.input) return false;
			const isValid = config.validate(config.input.value || '');
			config.input.setCustomValidity(isValid ? '' : config.message);
			showFieldError(config.input.id, isValid ? '' : config.message);
			return isValid;
		};

		const computeIsValid = () => Object.values(validators).every((config) => config?.input && config.validate(config.input.value || ''));

		const toggleButtonState = (isEnabled) => {
			if (!submitButton) return;
			submitButton.disabled = !isEnabled;
			submitButton.classList.toggle('is-disabled', !isEnabled);
		};

		updateSubmitState = () => {
			toggleButtonState(computeIsValid());
		};

		Object.values(validators).forEach((config) => {
			config.input?.addEventListener('input', () => {
				validateField(config);
				toggleButtonState(computeIsValid());
			});
		});

		editForm.addEventListener('submit', (event) => {
			event.preventDefault();
			let firstInvalid = null;
			Object.values(validators).forEach((config) => {
				if (!validateField(config) && !firstInvalid) {
					firstInvalid = config.input;
				}
			});

			const isValid = !firstInvalid;
			toggleButtonState(isValid);

			if (!isValid && firstInvalid) {
				firstInvalid.reportValidity();
				return;
			}

			editModalController?.closeModal();
		});

		toggleButtonState(false);
	}
});
