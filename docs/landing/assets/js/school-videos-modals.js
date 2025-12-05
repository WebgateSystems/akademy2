document.addEventListener('DOMContentLoaded', () => {
  const addVideoModal = document.getElementById('add-video-modal');
  const deleteVideoModal = document.getElementById('delete-video-modal');
  const fabButton = document.querySelector('.school-videos-fab');
  const deleteButtons = document.querySelectorAll('.js-delete-video');
  const addVideoForm = document.getElementById('add-video-form');
  const addVideoSubmitBtn = addVideoForm?.querySelector('button[type="submit"]');
  
  const filterTags = document.querySelectorAll('.filter-tag');
  filterTags.forEach(tag => {
    tag.addEventListener('click', () => {
      filterTags.forEach(t => t.classList.remove('is-active'));
      tag.classList.add('is-active');
    });
  });

  // View toggle functionality
  const viewToggleButtons = document.querySelectorAll('.view-toggle__button');
  const gridView = document.querySelector('.school-videos-grid');
  const tableView = document.querySelector('.teachers-panel');

  viewToggleButtons.forEach(button => {
    button.addEventListener('click', () => {
      const view = button.dataset.view;
      
      // Update active button
      viewToggleButtons.forEach(btn => btn.classList.remove('is-active'));
      button.classList.add('is-active');

      // Toggle views
      if (view === 'grid') {
        if (gridView) gridView.style.display = 'grid';
        if (tableView) tableView.style.display = 'none';
      } else if (view === 'list') {
        if (gridView) gridView.style.display = 'none';
        if (tableView) tableView.style.display = 'block';
      }
    });
  });

  function validateAddVideoForm() {
    if (!addVideoForm || !addVideoSubmitBtn) return;
    
    const topic = addVideoForm.querySelector('select[name="topic"]');
    const title = addVideoForm.querySelector('input[name="title"]');
    const description = addVideoForm.querySelector('input[name="description"]');
    const fileInput = document.getElementById('video-file-input');
    
    const isValid = 
      topic?.value !== '' &&
      title?.value.trim() !== '' &&
      description?.value.trim() !== '' &&
      fileInput?.files?.length > 0;
    
    addVideoSubmitBtn.disabled = !isValid;
  }

  if (addVideoForm) {
    addVideoForm.querySelectorAll('input, select').forEach(input => {
      input.addEventListener('input', validateAddVideoForm);
      input.addEventListener('change', validateAddVideoForm);
    });
  }

  if (fabButton && addVideoModal) {
    fabButton.addEventListener('click', () => {
      addVideoModal.setAttribute('aria-hidden', 'false');
      addVideoModal.classList.add('is-open');
      validateAddVideoForm();
    });
  }

  deleteButtons.forEach(deleteButton => {
    deleteButton.addEventListener('click', (e) => {
      e.stopPropagation();
      if (deleteVideoModal) {
        deleteVideoModal.setAttribute('aria-hidden', 'false');
        deleteVideoModal.classList.add('is-open');
      }
    });
  });

  document.querySelectorAll('.schools-modal__overlay').forEach(overlay => {
    overlay.addEventListener('click', () => {
      const modal = overlay.closest('.schools-modal');
      if (modal) {
        modal.setAttribute('aria-hidden', 'true');
        modal.classList.remove('is-open');
      }
    });
  });

  document.querySelectorAll('.schools-modal__close').forEach(closeBtn => {
    closeBtn.addEventListener('click', () => {
      const modal = closeBtn.closest('.schools-modal');
      if (modal) {
        modal.setAttribute('aria-hidden', 'true');
        modal.classList.remove('is-open');
      }
    });
  });

  if (addVideoForm) {
    addVideoForm.addEventListener('submit', (e) => {
      e.preventDefault();
      console.log('Video added');
      window.location.href = '/pages/pupil/school-videos/video-waiting.html';
    });
  }

  const cancelButtons = document.querySelectorAll('.schools-modal__secondary');
  cancelButtons.forEach(button => {
    button.addEventListener('click', () => {
      const modal = button.closest('.schools-modal');
      if (modal) {
        modal.setAttribute('aria-hidden', 'true');
        modal.classList.remove('is-open');
        if (modal.id === 'add-video-modal' && addVideoForm) {
          addVideoForm.reset();
          if (addVideoSubmitBtn) addVideoSubmitBtn.disabled = true;
        }
      }
    });
  });

  const deleteConfirmButton = deleteVideoModal?.querySelector('.schools-modal__primary--danger');
  if (deleteConfirmButton) {
    deleteConfirmButton.addEventListener('click', () => {
      console.log('Video deleted');
      deleteVideoModal.setAttribute('aria-hidden', 'true');
      deleteVideoModal.classList.remove('is-open');
    });
  }

  const fileInput = document.getElementById('video-file-input');
  if (fileInput) {
    fileInput.addEventListener('change', (e) => {
      const file = e.target.files[0];
      if (file) {
        console.log('File selected:', file.name);
      }
      validateAddVideoForm();
    });
  }
});
