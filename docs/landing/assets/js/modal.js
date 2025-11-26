document.addEventListener('DOMContentLoaded', () => {
	const initModal = ({ modalId, triggerSelector, onOpen, onClose }) => {
		const modal = document.getElementById(modalId);
		if (!modal) return null;

		const triggers = triggerSelector ? document.querySelectorAll(triggerSelector) : [];
		if (triggerSelector && triggers.length === 0) return null;

		const closeBtn = modal.querySelector('.schools-modal__close');
		const cancelBtn = modal.querySelector('.schools-modal__secondary');
		const overlay = modal.querySelector('.schools-modal__overlay');

		const openModal = () => {
			onOpen?.();
			modal.classList.add('is-open');
			modal.setAttribute('aria-hidden', 'false');
			document.body.style.overflow = 'hidden';
		};

		const closeModal = () => {
			modal.classList.remove('is-open');
			modal.setAttribute('aria-hidden', 'true');
			document.body.style.overflow = '';
			onClose?.();
		};

		triggers.forEach((trigger) => trigger.addEventListener('click', openModal));
		[closeBtn, cancelBtn, overlay].forEach((element) => {
			element?.addEventListener('click', closeModal);
		});
		document.addEventListener('keydown', (event) => {
			if (event.key === 'Escape' && modal.classList.contains('is-open')) {
				closeModal();
			}
		});

		return { modal, openModal, closeModal };
	};

	window.ModalUtils = { initModal };
});
