// Management Teachers - Handles teacher list, infinite scroll, modals
document.addEventListener('DOMContentLoaded', function() {
  // Check if we're on the teachers management page (not any other page with similar elements)
  // TEACHERS_ASSET_PATHS is only set on management/teachers page
  if (!window.TEACHERS_ASSET_PATHS || !document.getElementById('teachers-table-body')) return;

  const I18N = window.TEACHERS_I18N || {};
  let currentPage = 1;
  let isLoading = false;
  let hasMore = true;
  let allTeachers = [];
  let filteredTeachers = [];
  let isSearching = false;
  let currentSearchTerm = '';
  let searchTimeout = null;
  const perPage = 20;
  const SEARCH_MIN_LENGTH = 3;
  const tbody = document.getElementById('teachers-table-body');
  const loadingIndicator = document.getElementById('teachers-loading-indicator');
  const emptyMessage = document.getElementById('teachers-empty-message');
  const searchInput = document.getElementById('teachers-search-input');

  if (typeof window.ApiClient === 'undefined') {
    console.error('ApiClient not available');
    return;
  }

  const api = new window.ApiClient();
  const API_BASE = '/management/teachers';

  function renderTeacherRow(teacher) {
    const attrs = teacher.attributes || teacher;
    const name = [attrs.first_name, attrs.last_name].filter(Boolean).join(' ') || attrs.email;
    const birthDate = attrs.birth_date || '—';
    const email = attrs.email || '—';
    const phone = attrs.phone || '—';
    const teacherId = teacher.id || attrs.id;
    const row = document.createElement('tr');
    row.className = 'teachers-table__row';
    
    const isLocked = attrs.is_locked || attrs.locked_at;
    const enrollmentStatus = attrs.enrollment_status || 'none';
    const enrollmentId = attrs.enrollment_id;
    const isAwaitingApproval = enrollmentStatus === 'pending';
    
    const cells = [name, birthDate, email, phone].map(text => {
      const cell = document.createElement('td');
      cell.className = 'teachers-table__cell';
      cell.textContent = text;
      return cell;
    });
    
    const statusCell = document.createElement('td');
    statusCell.className = 'teachers-table__cell';
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
    actionsCell.className = 'teachers-table__cell teachers-table__cell--actions';
    const teachersActionsDiv = document.createElement('div');
    teachersActionsDiv.className = 'teachers-actions';
    
    if (isAwaitingApproval) {
      const approveBtn = document.createElement('button');
      approveBtn.className = 'teacher-action teacher-action--approve js-approve-teacher';
      approveBtn.type = 'button';
      approveBtn.setAttribute('data-teacher-id', teacherId);
      approveBtn.setAttribute('data-teacher-name', name);
      if (enrollmentId) approveBtn.setAttribute('data-enrollment-id', enrollmentId);
      const approveImg = document.createElement('img');
      approveImg.src = window.TEACHERS_ASSET_PATHS?.approveIcon || '/assets/icons/social/S/done.svg';
      approveImg.alt = '';
      approveBtn.appendChild(approveImg);
      
      const declineBtn = document.createElement('button');
      declineBtn.className = 'teacher-action teacher-action--reject js-decline-teacher';
      declineBtn.type = 'button';
      declineBtn.setAttribute('data-teacher-id', teacherId);
      declineBtn.setAttribute('data-teacher-name', name);
      if (enrollmentId) declineBtn.setAttribute('data-enrollment-id', enrollmentId);
      const declineImg = document.createElement('img');
      declineImg.src = window.TEACHERS_ASSET_PATHS?.declineIcon || '/assets/icons/social/S/close_red.svg';
      declineImg.alt = '';
      declineBtn.appendChild(declineImg);
      
      teachersActionsDiv.appendChild(approveBtn);
      teachersActionsDiv.appendChild(declineBtn);
    } else {
      const headmastersActionsDiv = document.createElement('div');
      headmastersActionsDiv.className = 'headmasters-actions';
      const details = document.createElement('details');
      details.className = 'headmasters-menu';
      const summary = document.createElement('summary');
      summary.setAttribute('aria-label', 'Open actions menu');
      
      // Use icon from asset path, fallback to text ellipsis if image fails
      const buttonIconPath = window.TEACHERS_ASSET_PATHS?.buttonIcon;
      if (buttonIconPath) {
        const img = document.createElement('img');
        img.src = buttonIconPath;
        img.alt = '';
        img.width = 18;
        img.height = 18;
        img.setAttribute('data-theme-icon', 'true');
        img.onerror = function() {
          // Replace with text if image fails to load
          summary.innerHTML = '<span style="font-size: 20px; font-weight: bold;">⋮</span>';
        };
        summary.appendChild(img);
      } else {
        // No icon path available, use text
        summary.innerHTML = '<span style="font-size: 20px; font-weight: bold;">⋮</span>';
      }
      
      const ul = document.createElement('ul');
      
      const editLi = document.createElement('li');
      const editBtn = document.createElement('button');
      editBtn.type = 'button';
      editBtn.setAttribute('data-action', 'edit-teacher');
      editBtn.setAttribute('data-teacher-id', teacherId);
      editBtn.setAttribute('data-teacher-first-name', attrs.first_name || '');
      editBtn.setAttribute('data-teacher-last-name', attrs.last_name || '');
      editBtn.setAttribute('data-teacher-email', attrs.email || '');
      editBtn.setAttribute('data-teacher-phone', attrs.phone || '');
      editBtn.setAttribute('data-teacher-birth-date', attrs.birth_date || '');
      editBtn.textContent = I18N.edit || 'Edytuj';
      editLi.appendChild(editBtn);
      
      const resendLi = document.createElement('li');
      const resendBtn = document.createElement('button');
      resendBtn.type = 'button';
      resendBtn.setAttribute('data-action', 'resend-invite');
      resendBtn.setAttribute('data-teacher-id', teacherId);
      resendBtn.textContent = I18N.resend_invite || 'Wyślij ponownie';
      resendLi.appendChild(resendBtn);
      
      const deactivateLi = document.createElement('li');
      const deactivateBtn = document.createElement('button');
      deactivateBtn.type = 'button';
      deactivateBtn.setAttribute('data-action', 'deactivate-teacher');
      deactivateBtn.setAttribute('data-teacher-id', teacherId);
      deactivateBtn.setAttribute('data-teacher-name', name);
      deactivateBtn.setAttribute('data-teacher-is-locked', isLocked ? 'true' : 'false');
      deactivateBtn.textContent = isLocked ? (I18N.activate || 'Aktywuj') : (I18N.deactivate || 'Dezaktywuj');
      deactivateLi.appendChild(deactivateBtn);
      
      ul.appendChild(editLi);
      ul.appendChild(resendLi);
      ul.appendChild(deactivateLi);
      details.appendChild(summary);
      details.appendChild(ul);
      headmastersActionsDiv.appendChild(details);
      teachersActionsDiv.appendChild(headmastersActionsDiv);
    }
    
    actionsCell.appendChild(teachersActionsDiv);
    cells.forEach(cell => row.appendChild(cell));
    row.appendChild(statusCell);
    row.appendChild(actionsCell);
    return row;
  }

  async function loadTeachers(page = 1, searchTerm = '') {
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
        let teachers = [];
        
        if (responseData.data?.data && Array.isArray(responseData.data.data)) {
          teachers = responseData.data.data;
        } else if (responseData.data && Array.isArray(responseData.data)) {
          teachers = responseData.data;
        } else if (Array.isArray(responseData)) {
          teachers = responseData;
        }
        
        const pagination = responseData.data?.pagination || responseData.pagination || {};

        if (page === 1) {
          allTeachers = [];
          tbody.innerHTML = '';
        }

        allTeachers = allTeachers.concat(teachers);
        filteredTeachers = allTeachers;
        teachers.forEach(teacher => tbody.appendChild(renderTeacherRow(teacher)));
        hasMore = pagination.has_more || false;
        currentPage = page;
        emptyMessage.style.display = allTeachers.length === 0 ? 'block' : 'none';
        setupTeacherMenus();
        setupEditTeacherHandler();
        setupResendInviteHandler();
        setupDeactivateTeacherHandler();
        setupApproveTeacherHandler();
        setupDeclineTeacherHandler();
      } else {
        console.error('Failed to load teachers:', result);
        emptyMessage.style.display = 'block';
      }
    } catch (error) {
      console.error('Error loading teachers:', error);
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
      loadTeachers(currentPage + 1, currentSearchTerm);
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
        allTeachers = [];
        tbody.innerHTML = '';
        loadTeachers(1);
        return;
      }

      if (searchTerm.length >= SEARCH_MIN_LENGTH) {
        isSearching = true;
        searchTimeout = setTimeout(() => {
          currentPage = 1;
          hasMore = true;
          allTeachers = [];
          tbody.innerHTML = '';
          loadTeachers(1, searchTerm);
        }, 300);
      } else {
        isSearching = true;
        const searchTermLower = searchTerm.toLowerCase();
        filteredTeachers = allTeachers.filter(teacher => {
          const attrs = teacher.attributes || teacher;
          const name = [attrs.first_name, attrs.last_name].filter(Boolean).join(' ').toLowerCase();
          return name.includes(searchTermLower) || (attrs.email || '').toLowerCase().includes(searchTermLower);
        });
        tbody.innerHTML = '';
        filteredTeachers.forEach(teacher => tbody.appendChild(renderTeacherRow(teacher)));
        emptyMessage.style.display = filteredTeachers.length === 0 ? 'block' : 'none';
        setupTeacherMenus();
      }
    });
  }

  loadTeachers(1);

  function setupTeacherMenus() {
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

  function setupEditTeacherHandler() {
    tbody.removeEventListener('click', handleEditTeacherClick, true);
    tbody.addEventListener('click', handleEditTeacherClick, true);
  }

  async function handleEditTeacherClick(e) {
    const btn = e.target.closest('[data-action="edit-teacher"]');
    if (!btn) return;
    e.preventDefault(); e.stopPropagation();
    const modal = document.getElementById('edit-teacher-modal');
    if (!modal) return;
    const teacherId = btn.getAttribute('data-teacher-id');
    document.getElementById('edit-teacher-id').value = teacherId;
    document.getElementById('edit-teacher-first-name').value = btn.getAttribute('data-teacher-first-name') || '';
    document.getElementById('edit-teacher-last-name').value = btn.getAttribute('data-teacher-last-name') || '';
    document.getElementById('edit-teacher-email').value = btn.getAttribute('data-teacher-email') || '';
    document.getElementById('edit-teacher-phone').value = btn.getAttribute('data-teacher-phone') || '';
    const birthDate = btn.getAttribute('data-teacher-birth-date') || '';
    if (birthDate) {
      const parts = birthDate.split('.');
      if (parts.length === 3) {
        document.getElementById('edit-teacher-birth-date').value = `${parts[2]}-${parts[1].padStart(2, '0')}-${parts[0].padStart(2, '0')}`;
      }
    }
    modal.setAttribute('aria-hidden', 'false'); modal.classList.add('is-open');
    const menu = btn.closest('.headmasters-menu');
    if (menu) menu.open = false;
  }

  const addForm = document.getElementById('add-teacher-form');
  if (addForm) {
    addForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const submitBtn = addForm.querySelector('button[type="submit"]');
      const originalText = submitBtn.textContent;
      submitBtn.disabled = true;
      submitBtn.textContent = I18N.adding || 'Dodawanie...';
      try {
        const formData = new FormData(addForm);
        const birthDateRaw = formData.get('teacher[metadata][birth_date]') || '';
        let birthDate = '';
        if (birthDateRaw) {
          const [year, month, day] = birthDateRaw.split('-');
          birthDate = `${day}.${month}.${year}`;
        }
        const data = {
          teacher: {
            school_id: window.MANAGEMENT_SCHOOL_ID,
            first_name: formData.get('teacher[first_name]'),
            last_name: formData.get('teacher[last_name]'),
            email: formData.get('teacher[email]'),
            metadata: { phone: formData.get('teacher[metadata][phone]') || '', birth_date: birthDate }
          }
        };
        const result = await api.post(API_BASE, data);
        if (result.success) {
          const modal = document.getElementById('add-teacher-modal');
          if (modal) { modal.setAttribute('aria-hidden', 'true'); modal.classList.remove('is-open'); addForm.reset(); }
          currentPage = 1; hasMore = true; allTeachers = []; if (searchInput) searchInput.value = '';
          loadTeachers(1);
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

  const editForm = document.getElementById('edit-teacher-form');
  if (editForm) {
    editForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const submitBtn = editForm.querySelector('button[type="submit"]');
      const originalText = submitBtn.textContent;
      const teacherId = document.getElementById('edit-teacher-id').value;
      submitBtn.disabled = true;
      submitBtn.textContent = I18N.saving || 'Zapisywanie...';
      try {
        const formData = new FormData(editForm);
        const birthDateRaw = formData.get('teacher[metadata][birth_date]') || '';
        let birthDate = '';
        if (birthDateRaw) {
          const [year, month, day] = birthDateRaw.split('-');
          birthDate = `${day}.${month}.${year}`;
        }
        const data = {
          teacher: {
            school_id: window.MANAGEMENT_SCHOOL_ID,
            first_name: formData.get('teacher[first_name]'),
            last_name: formData.get('teacher[last_name]'),
            email: formData.get('teacher[email]'),
            metadata: { phone: formData.get('teacher[metadata][phone]') || '', birth_date: birthDate }
          }
        };
        const result = await api.patch(`${API_BASE}/${teacherId}`, data);
        if (result.success) {
          const modal = document.getElementById('edit-teacher-modal');
          if (modal) { modal.setAttribute('aria-hidden', 'true'); modal.classList.remove('is-open'); }
          currentPage = 1; hasMore = true; allTeachers = []; if (searchInput) searchInput.value = '';
          loadTeachers(1);
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
    const teacherId = btn.getAttribute('data-teacher-id');
    const originalText = btn.textContent;
    btn.disabled = true;
    btn.textContent = I18N.sending || 'Wysyłanie...';
    try {
      const result = await api.post(`${API_BASE}/${teacherId}/resend_invite`, {});
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

  let deactivateTeacherId = null;
  function setupDeactivateTeacherHandler() {
    tbody.removeEventListener('click', handleDeactivateTeacherClick, true);
    tbody.addEventListener('click', handleDeactivateTeacherClick, true);
  }

  function handleDeactivateTeacherClick(e) {
    const btn = e.target.closest('[data-action="deactivate-teacher"]');
    if (!btn) return;
    e.preventDefault(); e.stopPropagation();
    deactivateTeacherId = btn.getAttribute('data-teacher-id');
    const name = btn.getAttribute('data-teacher-name') || '';
    const deactivateNameEl = document.querySelector('[data-deactivate-name]');
    if (deactivateNameEl) deactivateNameEl.textContent = name;
    const menu = btn.closest('.headmasters-menu');
    if (menu) menu.open = false;
    const modal = document.getElementById('deactivate-teacher-modal');
    if (modal) { modal.setAttribute('aria-hidden', 'false'); modal.classList.add('is-open'); }
  }

  const deactivateBtn = document.getElementById('deactivate-teacher-confirm-btn');
  if (deactivateBtn) {
    deactivateBtn.addEventListener('click', async () => {
      if (!deactivateTeacherId) return;
      const originalText = deactivateBtn.textContent;
      deactivateBtn.disabled = true;
      deactivateBtn.textContent = I18N.processing || 'Przetwarzanie...';
      try {
        const result = await api.post(`${API_BASE}/${deactivateTeacherId}/lock`, {});
        if (result.success) {
          const modal = document.getElementById('deactivate-teacher-modal');
          if (modal) { modal.setAttribute('aria-hidden', 'true'); modal.classList.remove('is-open'); }
          currentPage = 1; hasMore = true; allTeachers = [];
          loadTeachers(1);
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

  let approveTeacherId = null;
  function setupApproveTeacherHandler() {
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.js-approve-teacher')) return;
      const btn = e.target.closest('.js-approve-teacher');
      approveTeacherId = btn.getAttribute('data-teacher-id');
      const modal = document.getElementById('approve-teacher-modal');
      if (modal) { modal.setAttribute('aria-hidden', 'false'); modal.classList.add('is-open'); }
    });
  }

  const approveBtn = document.getElementById('approve-teacher-confirm-btn');
  if (approveBtn) {
    approveBtn.addEventListener('click', async () => {
      if (!approveTeacherId) return;
      const originalText = approveBtn.textContent;
      approveBtn.disabled = true;
      approveBtn.textContent = I18N.processing || 'Przetwarzanie...';
      try {
        const result = await api.post(`${API_BASE}/${approveTeacherId}/approve`, {});
        if (result.success) {
          const modal = document.getElementById('approve-teacher-modal');
          if (modal) { modal.setAttribute('aria-hidden', 'true'); modal.classList.remove('is-open'); }
          allTeachers = []; currentPage = 1; hasMore = true;
          await loadTeachers(1, currentSearchTerm);
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

  let declineTeacherId = null;
  function setupDeclineTeacherHandler() {
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.js-decline-teacher')) return;
      const btn = e.target.closest('.js-decline-teacher');
      declineTeacherId = btn.getAttribute('data-teacher-id');
      const modal = document.getElementById('decline-teacher-modal');
      if (modal) { modal.setAttribute('aria-hidden', 'false'); modal.classList.add('is-open'); }
    });
  }

  const declineBtn = document.getElementById('decline-teacher-confirm-btn');
  if (declineBtn) {
    declineBtn.addEventListener('click', async () => {
      if (!declineTeacherId) return;
      const originalText = declineBtn.textContent;
      declineBtn.disabled = true;
      declineBtn.textContent = I18N.processing || 'Przetwarzanie...';
      try {
        const result = await api.post(`${API_BASE}/${declineTeacherId}/decline`, {});
        if (result.success) {
          const modal = document.getElementById('decline-teacher-modal');
          if (modal) { modal.setAttribute('aria-hidden', 'true'); modal.classList.remove('is-open'); }
          allTeachers = []; currentPage = 1; hasMore = true;
          await loadTeachers(1, currentSearchTerm);
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

