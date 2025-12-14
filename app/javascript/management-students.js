// Management Students - Handles student list, infinite scroll, modals
document.addEventListener('DOMContentLoaded', function() {
  // Check if we're on the students management page (not dashboard/students)
  // STUDENTS_ASSET_PATHS is only set on management/students page
  if (!window.STUDENTS_ASSET_PATHS || !document.getElementById('students-table-body')) return;

  const I18N = window.STUDENTS_I18N || {};
  let currentPage = 1;
  let isLoading = false;
  let hasMore = true;
  let allStudents = [];
  let filteredStudents = [];
  let isSearching = false;
  let currentSearchTerm = '';
  let searchTimeout = null;
  const perPage = 20;
  const SEARCH_MIN_LENGTH = 3;
  const tbody = document.getElementById('students-table-body');
  const loadingIndicator = document.getElementById('students-loading-indicator');
  const emptyMessage = document.getElementById('students-empty-message');
  const searchInput = document.getElementById('students-search-input');

  if (typeof window.ApiClient === 'undefined') {
    console.error('ApiClient not available');
    return;
  }

  const api = new window.ApiClient();
  const API_BASE = '/management/students';

  function renderStudentRow(student) {
    const attrs = student.attributes || student;
    const name = [attrs.first_name, attrs.last_name].filter(Boolean).join(' ') || attrs.email;
    const birthDate = attrs.birth_date || '—';
    const email = attrs.email || '—';
    const phone = attrs.phone || '—';
    const className = attrs.class_name || '—';
    const studentId = student.id || attrs.id;
    const row = document.createElement('tr');
    row.className = 'students-table__row';
    
    const isLocked = attrs.is_locked || attrs.locked_at;
    const isConfirmed = attrs.is_confirmed || attrs.confirmed_at;
    const isAwaitingApproval = !isConfirmed;
    
    const cells = [name, birthDate, email, phone, className].map(text => {
      const cell = document.createElement('td');
      cell.className = 'students-table__cell';
      cell.textContent = text;
      return cell;
    });
    
    const statusCell = document.createElement('td');
    statusCell.className = 'students-table__cell';
    const statusBadge = document.createElement('span');
    if (isAwaitingApproval) {
      statusBadge.textContent = I18N.status_awaiting || 'Oczekuje';
      statusBadge.style.color = 'var(--content-secondary)';
    } else if (isLocked) {
      statusBadge.textContent = I18N.status_inactive || 'Nieaktywny';
      statusBadge.style.color = 'var(--state-error)';
    } else {
      statusBadge.textContent = I18N.status_active || 'Aktywny';
      statusBadge.style.color = 'var(--state-success)';
    }
    statusBadge.style.fontWeight = '500';
    statusCell.appendChild(statusBadge);
    
    const actionsCell = document.createElement('td');
    actionsCell.className = 'students-table__cell students-table__cell--actions';
    const studentsActionsDiv = document.createElement('div');
    studentsActionsDiv.className = 'students-actions';
    
    if (isAwaitingApproval) {
      const approveBtn = document.createElement('button');
      approveBtn.className = 'student-action student-action--approve js-approve-student';
      approveBtn.type = 'button';
      approveBtn.setAttribute('data-student-id', studentId);
      approveBtn.setAttribute('data-student-name', name);
      const approveImg = document.createElement('img');
      approveImg.src = window.STUDENTS_ASSET_PATHS?.approveIcon || '/assets/icons/social/S/done.svg';
      approveImg.alt = '';
      approveBtn.appendChild(approveImg);
      
      const declineBtn = document.createElement('button');
      declineBtn.className = 'student-action student-action--reject js-decline-student';
      declineBtn.type = 'button';
      declineBtn.setAttribute('data-student-id', studentId);
      declineBtn.setAttribute('data-student-name', name);
      const declineImg = document.createElement('img');
      declineImg.src = window.STUDENTS_ASSET_PATHS?.declineIcon || '/assets/icons/social/S/close_red.svg';
      declineImg.alt = '';
      declineBtn.appendChild(declineImg);
      
      studentsActionsDiv.appendChild(approveBtn);
      studentsActionsDiv.appendChild(declineBtn);
    } else {
      const headmastersActionsDiv = document.createElement('div');
      headmastersActionsDiv.className = 'headmasters-actions';
      const details = document.createElement('details');
      details.className = 'headmasters-menu';
      const summary = document.createElement('summary');
      const img = document.createElement('img');
      img.src = window.STUDENTS_ASSET_PATHS?.buttonIcon || '/assets/icons/social/S/button-3.svg';
      img.alt = '';
      img.setAttribute('data-theme-icon', 'true');
      summary.appendChild(img);
      
      const ul = document.createElement('ul');
      
      const editLi = document.createElement('li');
      const editBtn = document.createElement('button');
      editBtn.type = 'button';
      editBtn.setAttribute('data-action', 'edit-student');
      editBtn.setAttribute('data-student-id', studentId);
      editBtn.setAttribute('data-student-first-name', attrs.first_name || '');
      editBtn.setAttribute('data-student-last-name', attrs.last_name || '');
      editBtn.setAttribute('data-student-email', attrs.email || '');
      editBtn.setAttribute('data-student-phone', attrs.phone || '');
      editBtn.setAttribute('data-student-birth-date', attrs.birth_date || '');
      editBtn.setAttribute('data-student-class-name', attrs.class_name || '');
      editBtn.textContent = I18N.edit || 'Edytuj';
      editLi.appendChild(editBtn);
      
      const resendLi = document.createElement('li');
      const resendBtn = document.createElement('button');
      resendBtn.type = 'button';
      resendBtn.setAttribute('data-action', 'resend-invite');
      resendBtn.setAttribute('data-student-id', studentId);
      resendBtn.textContent = I18N.resend_invite || 'Wyślij ponownie';
      resendLi.appendChild(resendBtn);
      
      const deactivateLi = document.createElement('li');
      const deactivateBtn = document.createElement('button');
      deactivateBtn.type = 'button';
      deactivateBtn.setAttribute('data-action', 'deactivate-student');
      deactivateBtn.setAttribute('data-student-id', studentId);
      deactivateBtn.setAttribute('data-student-name', name);
      deactivateBtn.setAttribute('data-student-is-locked', isLocked ? 'true' : 'false');
      deactivateBtn.textContent = isLocked ? (I18N.activate || 'Aktywuj') : (I18N.deactivate || 'Dezaktywuj');
      deactivateLi.appendChild(deactivateBtn);
      
      ul.appendChild(editLi);
      ul.appendChild(resendLi);
      ul.appendChild(deactivateLi);
      details.appendChild(summary);
      details.appendChild(ul);
      headmastersActionsDiv.appendChild(details);
      studentsActionsDiv.appendChild(headmastersActionsDiv);
    }
    
    actionsCell.appendChild(studentsActionsDiv);
    cells.forEach(cell => row.appendChild(cell));
    row.appendChild(statusCell);
    row.appendChild(actionsCell);
    return row;
  }

  async function loadStudents(page = 1, searchTerm = '') {
    if (isLoading || (!hasMore && page > 1)) return;
    isLoading = true;
    loadingIndicator.style.display = 'block';

    try {
      let url = `${API_BASE}?page=${page}&per_page=${perPage}`;
      if (searchTerm && searchTerm.length >= SEARCH_MIN_LENGTH) {
        url += `&search=${encodeURIComponent(searchTerm)}`;
      }
      const result = await api.get(url);
      
      if (result.success && result.data) {
        const responseData = result.data;
        let students = [];
        
        if (responseData.data?.data && Array.isArray(responseData.data.data)) {
          students = responseData.data.data;
        } else if (responseData.data && Array.isArray(responseData.data)) {
          students = responseData.data;
        } else if (Array.isArray(responseData)) {
          students = responseData;
        }
        
        const pagination = responseData.data?.pagination || responseData.pagination || {};

        if (page === 1) {
          allStudents = [];
          tbody.innerHTML = '';
        }

        allStudents = allStudents.concat(students);
        filteredStudents = allStudents;
        students.forEach(student => tbody.appendChild(renderStudentRow(student)));
        hasMore = pagination.has_more || false;
        currentPage = page;
        emptyMessage.style.display = allStudents.length === 0 ? 'block' : 'none';
        setupStudentMenus();
        setupEditStudentHandler();
        setupResendInviteHandler();
        setupDeactivateStudentHandler();
        setupApproveStudentHandler();
        setupDeclineStudentHandler();
      } else {
        console.error('Failed to load students:', result);
        emptyMessage.style.display = 'block';
      }
    } catch (error) {
      console.error('Error loading students:', error);
      emptyMessage.style.display = 'block';
    } finally {
      isLoading = false;
      loadingIndicator.style.display = 'none';
    }
  }

  function handleScroll() {
    if (isLoading || !hasMore) return;
    if (isSearching && currentSearchTerm.length < SEARCH_MIN_LENGTH) return;
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    const windowHeight = window.innerHeight;
    const documentHeight = document.documentElement.scrollHeight;
    if (scrollTop + windowHeight >= documentHeight - 200) {
      loadStudents(currentPage + 1, currentSearchTerm);
    }
  }

  let scrollTimeout;
  window.addEventListener('scroll', function() {
    if (scrollTimeout) clearTimeout(scrollTimeout);
    scrollTimeout = setTimeout(handleScroll, 100);
  });

  if (searchInput) {
    searchInput.addEventListener('input', function() {
      const searchTerm = this.value.trim();
      currentSearchTerm = searchTerm;
      if (searchTimeout) clearTimeout(searchTimeout);

      if (!searchTerm) {
        isSearching = false;
        currentPage = 1;
        hasMore = true;
        allStudents = [];
        tbody.innerHTML = '';
        loadStudents(1);
        return;
      }

      if (searchTerm.length >= SEARCH_MIN_LENGTH) {
        isSearching = true;
        searchTimeout = setTimeout(() => {
          currentPage = 1;
          hasMore = true;
          allStudents = [];
          tbody.innerHTML = '';
          loadStudents(1, searchTerm);
        }, 300);
      } else {
        isSearching = true;
        const searchTermLower = searchTerm.toLowerCase();
        filteredStudents = allStudents.filter(student => {
          const attrs = student.attributes || student;
          const name = [attrs.first_name, attrs.last_name].filter(Boolean).join(' ').toLowerCase();
          return name.includes(searchTermLower) || (attrs.email || '').toLowerCase().includes(searchTermLower);
        });
        tbody.innerHTML = '';
        filteredStudents.forEach(student => tbody.appendChild(renderStudentRow(student)));
        emptyMessage.style.display = filteredStudents.length === 0 ? 'block' : 'none';
        setupStudentMenus();
      }
    });
  }

  loadStudents(1);

  function setupStudentMenus() {
    const menus = document.querySelectorAll('.headmasters-menu');
    menus.forEach(menu => {
      const summary = menu.querySelector('summary');
      if (!summary) return;
      menu.addEventListener('toggle', function() {
        if (menu.open) {
          menus.forEach(m => { if (m !== menu && m.open) m.open = false; });
          requestAnimationFrame(() => {
            const ul = menu.querySelector('ul');
            if (!ul) return;
            const summaryRect = summary.getBoundingClientRect();
            ul.style.cssText = `position: fixed; z-index: 999999; top: ${summaryRect.bottom + 10}px; right: ${window.innerWidth - summaryRect.right}px;`;
          });
        }
      });
    });
    document.addEventListener('click', e => {
      if (!e.target.closest('.headmasters-menu')) menus.forEach(m => { if (m.open) m.open = false; });
    }, true);
  }

  document.querySelectorAll('[data-open-modal]').forEach(btn => {
    btn.addEventListener('click', () => {
      const modal = document.getElementById(btn.getAttribute('data-open-modal'));
      if (modal) { modal.setAttribute('aria-hidden', 'false'); modal.classList.add('is-open'); }
    });
  });

  document.querySelectorAll('[data-close-modal]').forEach(btn => {
    btn.addEventListener('click', function() {
      const modal = document.getElementById(this.getAttribute('data-close-modal'));
      if (modal) { modal.setAttribute('aria-hidden', 'true'); modal.classList.remove('is-open'); }
    });
  });

  document.querySelectorAll('.schools-modal__overlay').forEach(overlay => {
    overlay.addEventListener('click', function() {
      const modal = this.closest('.schools-modal');
      if (modal) { modal.setAttribute('aria-hidden', 'true'); modal.classList.remove('is-open'); }
    });
  });

  function setupEditStudentHandler() {
    tbody.removeEventListener('click', handleEditStudentClick, true);
    tbody.addEventListener('click', handleEditStudentClick, true);
  }

  async function handleEditStudentClick(e) {
    const btn = e.target.closest('[data-action="edit-student"]');
    if (!btn) return;
    e.preventDefault(); e.stopPropagation();
    const modal = document.getElementById('edit-student-modal');
    if (!modal) return;
    const studentId = btn.getAttribute('data-student-id');
    document.getElementById('edit-student-id').value = studentId;
    document.getElementById('edit-student-first-name').value = btn.getAttribute('data-student-first-name') || '';
    document.getElementById('edit-student-last-name').value = btn.getAttribute('data-student-last-name') || '';
    document.getElementById('edit-student-email').value = btn.getAttribute('data-student-email') || '';
    document.getElementById('edit-student-phone').value = btn.getAttribute('data-student-phone') || '';
    
    const birthDate = btn.getAttribute('data-student-birth-date') || '';
    if (birthDate) {
      const parts = birthDate.split('.');
      if (parts.length === 3) {
        document.getElementById('edit-student-birth-date').value = `${parts[2]}-${parts[1].padStart(2, '0')}-${parts[0].padStart(2, '0')}`;
      }
    }
    
    // Set class selection
    const className = btn.getAttribute('data-student-class-name') || '';
    const classField = document.getElementById('edit-student-class');
    if (classField && className && window.SCHOOL_CLASSES) {
      const matchingClass = window.SCHOOL_CLASSES.find(c => String(c.name).trim() === String(className).trim());
      if (matchingClass) {
        classField.value = matchingClass.id;
      }
    }
    
    modal.setAttribute('aria-hidden', 'false'); modal.classList.add('is-open');
    const menu = btn.closest('.headmasters-menu');
    if (menu) menu.open = false;
  }

  const addForm = document.getElementById('add-student-form');
  if (addForm) {
    addForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const submitBtn = addForm.querySelector('button[type="submit"]');
      const originalText = submitBtn.textContent;
      submitBtn.disabled = true;
      submitBtn.textContent = I18N.adding || 'Dodawanie...';
      try {
        const formData = new FormData(addForm);
        const birthDateRaw = formData.get('student[metadata][birth_date]') || '';
        let birthDate = '';
        if (birthDateRaw) {
          const [year, month, day] = birthDateRaw.split('-');
          birthDate = `${day}.${month}.${year}`;
        }
        const data = {
          student: {
            school_id: window.MANAGEMENT_SCHOOL_ID,
            first_name: formData.get('student[first_name]'),
            last_name: formData.get('student[last_name]'),
            email: formData.get('student[email]'),
            school_class_id: formData.get('student[school_class_id]') || null,
            metadata: { phone: formData.get('student[metadata][phone]') || '', birth_date: birthDate }
          }
        };
        const result = await api.post(API_BASE, data);
        if (result.success) {
          const modal = document.getElementById('add-student-modal');
          if (modal) { modal.setAttribute('aria-hidden', 'true'); modal.classList.remove('is-open'); addForm.reset(); }
          currentPage = 1; hasMore = true; allStudents = []; if (searchInput) searchInput.value = '';
          loadStudents(1);
        } else {
          alert('Error: ' + (result.error || I18N.error_create));
          submitBtn.disabled = false; submitBtn.textContent = originalText;
        }
      } catch (error) {
        alert('Error: ' + (error.message || I18N.error_unknown));
        submitBtn.disabled = false; submitBtn.textContent = originalText;
      }
    });
  }

  const editForm = document.getElementById('edit-student-form');
  if (editForm) {
    editForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const submitBtn = editForm.querySelector('button[type="submit"]');
      const originalText = submitBtn.textContent;
      const studentId = document.getElementById('edit-student-id').value;
      submitBtn.disabled = true;
      submitBtn.textContent = I18N.saving || 'Zapisywanie...';
      try {
        const formData = new FormData(editForm);
        const birthDateRaw = formData.get('student[metadata][birth_date]') || '';
        let birthDate = '';
        if (birthDateRaw) {
          const [year, month, day] = birthDateRaw.split('-');
          birthDate = `${day}.${month}.${year}`;
        }
        const data = {
          student: {
            school_id: window.MANAGEMENT_SCHOOL_ID,
            first_name: formData.get('student[first_name]'),
            last_name: formData.get('student[last_name]'),
            email: formData.get('student[email]'),
            school_class_id: formData.get('student[school_class_id]') || null,
            metadata: { phone: formData.get('student[metadata][phone]') || '', birth_date: birthDate }
          }
        };
        const result = await api.patch(`${API_BASE}/${studentId}`, data);
        if (result.success) {
          const modal = document.getElementById('edit-student-modal');
          if (modal) { modal.setAttribute('aria-hidden', 'true'); modal.classList.remove('is-open'); }
          currentPage = 1; hasMore = true; allStudents = []; if (searchInput) searchInput.value = '';
          loadStudents(1);
        } else {
          alert('Error: ' + (result.error || I18N.error_update));
          submitBtn.disabled = false; submitBtn.textContent = originalText;
        }
      } catch (error) {
        alert('Error: ' + (error.message || I18N.error_unknown));
        submitBtn.disabled = false; submitBtn.textContent = originalText;
      }
    });
  }

  function setupResendInviteHandler() {
    tbody.removeEventListener('click', handleResendInviteClick, true);
    tbody.addEventListener('click', handleResendInviteClick, true);
  }

  async function handleResendInviteClick(e) {
    const btn = e.target.closest('[data-action="resend-invite"]');
    if (!btn) return;
    e.preventDefault(); e.stopPropagation();
    const studentId = btn.getAttribute('data-student-id');
    const originalText = btn.textContent;
    btn.disabled = true;
    btn.textContent = I18N.sending || 'Wysyłanie...';
    try {
      const result = await api.post(`${API_BASE}/${studentId}/resend_invite`, {});
      if (result.success) {
        btn.textContent = I18N.sent || 'Wysłano!';
        btn.style.color = 'var(--state-success)';
        const menu = btn.closest('.headmasters-menu');
        if (menu) menu.open = false;
        setTimeout(() => { btn.disabled = false; btn.textContent = originalText; btn.style.color = ''; }, 2000);
      } else {
        btn.disabled = false; btn.textContent = originalText;
      }
    } catch (error) {
      btn.disabled = false; btn.textContent = originalText;
    }
  }

  let deactivateStudentId = null;
  function setupDeactivateStudentHandler() {
    tbody.removeEventListener('click', handleDeactivateStudentClick, true);
    tbody.addEventListener('click', handleDeactivateStudentClick, true);
  }

  function handleDeactivateStudentClick(e) {
    const btn = e.target.closest('[data-action="deactivate-student"]');
    if (!btn) return;
    e.preventDefault(); e.stopPropagation();
    deactivateStudentId = btn.getAttribute('data-student-id');
    const name = btn.getAttribute('data-student-name') || '';
    const deactivateNameEl = document.querySelector('[data-deactivate-name]');
    if (deactivateNameEl) deactivateNameEl.textContent = name;
    const menu = btn.closest('.headmasters-menu');
    if (menu) menu.open = false;
    const modal = document.getElementById('deactivate-student-modal');
    if (modal) { modal.setAttribute('aria-hidden', 'false'); modal.classList.add('is-open'); }
  }

  const deactivateBtn = document.getElementById('deactivate-student-confirm-btn');
  if (deactivateBtn) {
    deactivateBtn.addEventListener('click', async () => {
      if (!deactivateStudentId) return;
      const originalText = deactivateBtn.textContent;
      deactivateBtn.disabled = true;
      deactivateBtn.textContent = I18N.processing || 'Przetwarzanie...';
      try {
        const result = await api.post(`${API_BASE}/${deactivateStudentId}/lock`, {});
        if (result.success) {
          const modal = document.getElementById('deactivate-student-modal');
          if (modal) { modal.setAttribute('aria-hidden', 'true'); modal.classList.remove('is-open'); }
          currentPage = 1; hasMore = true; allStudents = [];
          loadStudents(1);
        } else {
          alert('Error: ' + (result.error || I18N.error_unknown));
          deactivateBtn.disabled = false; deactivateBtn.textContent = originalText;
        }
      } catch (error) {
        alert('Error: ' + (error.message || I18N.error_unknown));
        deactivateBtn.disabled = false; deactivateBtn.textContent = originalText;
      }
    });
  }

  let approveStudentId = null;
  function setupApproveStudentHandler() {
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.js-approve-student')) return;
      const btn = e.target.closest('.js-approve-student');
      approveStudentId = btn.getAttribute('data-student-id');
      const modal = document.getElementById('approve-student-modal');
      if (modal) { modal.setAttribute('aria-hidden', 'false'); modal.classList.add('is-open'); }
    });
  }

  const approveBtn = document.getElementById('approve-student-confirm-btn');
  if (approveBtn) {
    approveBtn.addEventListener('click', async () => {
      if (!approveStudentId) return;
      const originalText = approveBtn.textContent;
      approveBtn.disabled = true;
      approveBtn.textContent = I18N.processing || 'Przetwarzanie...';
      try {
        const result = await api.post(`${API_BASE}/${approveStudentId}/approve`, {});
        if (result.success) {
          const modal = document.getElementById('approve-student-modal');
          if (modal) { modal.setAttribute('aria-hidden', 'true'); modal.classList.remove('is-open'); }
          allStudents = []; currentPage = 1; hasMore = true;
          await loadStudents(1, currentSearchTerm);
        } else {
          alert('Error: ' + (result.error || I18N.error_unknown));
          approveBtn.disabled = false; approveBtn.textContent = originalText;
        }
      } catch (error) {
        alert('Error: ' + (error.message || I18N.error_unknown));
        approveBtn.disabled = false; approveBtn.textContent = originalText;
      }
    });
  }

  let declineStudentId = null;
  function setupDeclineStudentHandler() {
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.js-decline-student')) return;
      const btn = e.target.closest('.js-decline-student');
      declineStudentId = btn.getAttribute('data-student-id');
      const modal = document.getElementById('decline-student-modal');
      if (modal) { modal.setAttribute('aria-hidden', 'false'); modal.classList.add('is-open'); }
    });
  }

  const declineBtn = document.getElementById('decline-student-confirm-btn');
  if (declineBtn) {
    declineBtn.addEventListener('click', async () => {
      if (!declineStudentId) return;
      const originalText = declineBtn.textContent;
      declineBtn.disabled = true;
      declineBtn.textContent = I18N.processing || 'Przetwarzanie...';
      try {
        const result = await api.delete(`${API_BASE}/${declineStudentId}/decline`);
        if (result.success) {
          const modal = document.getElementById('decline-student-modal');
          if (modal) { modal.setAttribute('aria-hidden', 'true'); modal.classList.remove('is-open'); }
          allStudents = []; currentPage = 1; hasMore = true;
          await loadStudents(1, currentSearchTerm);
        } else {
          alert('Error: ' + (result.error || I18N.error_unknown));
          declineBtn.disabled = false; declineBtn.textContent = originalText;
        }
      } catch (error) {
        alert('Error: ' + (error.message || I18N.error_unknown));
        declineBtn.disabled = false; declineBtn.textContent = originalText;
      }
    });
  }
});

