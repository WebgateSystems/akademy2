// Management Parents page JavaScript
document.addEventListener('DOMContentLoaded', function() {
  // Check if we're on the parents page
  if (!document.getElementById('parents-table-body')) {
    return;
  }

  // Infinite scroll implementation
  let currentPage = 1;
  let isLoading = false;
  let hasMore = true;
  let allParents = [];
  let filteredParents = [];
  let isSearching = false;
  let currentSearchTerm = '';
  let searchTimeout = null;
  const perPage = 20;
  const SEARCH_MIN_LENGTH = 3;
  const tbody = document.getElementById('parents-table-body');
  const loadingIndicator = document.getElementById('parents-loading-indicator');
  const emptyMessage = document.getElementById('parents-empty-message');
  const searchInput = document.getElementById('parents-search-input');

  if (typeof window.ApiClient === 'undefined') {
    console.error('ApiClient not available. Make sure api_client.js is loaded.');
    return;
  }

  const api = new window.ApiClient();
  const API_BASE = '/management/parents';

  // Student autocomplete functionality
  let selectedStudents = {
    add: [],
    edit: []
  };
  let autocompleteTimeout = null;

  // Function to render a parent row
  function renderParentRow(parent) {
    // Handle JSON:API format: {id, type, attributes: {...}}
    // Or plain object: {id, first_name, ...}
    if (!parent || (!parent.id && !parent.attributes)) {
      console.warn('Invalid parent data:', parent);
      return null;
    }
    
    const attrs = parent.attributes || parent;
    const parentId = parent.id || attrs.id;
    
    // Validate that we have at least an ID
    if (!parentId) {
      console.warn('Parent missing ID:', parent);
      return null;
    }
    
    const name = [attrs.first_name, attrs.last_name].filter(Boolean).join(' ') || attrs.email || '—';
    const email = attrs.email || '—';
    const phone = attrs.phone || '—';
    const students = attrs.students || [];
    const isLocked = attrs.is_locked || attrs.locked_at;

    const row = document.createElement('tr');
    row.className = 'teachers-table__row';
    
    // Name cell
    const nameCell = document.createElement('td');
    nameCell.className = 'teachers-table__cell';
    nameCell.textContent = name;
    
    // Email cell
    const emailCell = document.createElement('td');
    emailCell.className = 'teachers-table__cell';
    emailCell.textContent = email;
    
    // Phone cell
    const phoneCell = document.createElement('td');
    phoneCell.className = 'teachers-table__cell';
    phoneCell.textContent = phone;
    
    // Children cell
    const childrenCell = document.createElement('td');
    childrenCell.className = 'teachers-table__cell';
    if (students.length > 0) {
      const childrenContainer = document.createElement('div');
      childrenContainer.style.display = 'flex';
      childrenContainer.style.gap = '8px';
      childrenContainer.style.flexWrap = 'wrap';
      students.forEach(student => {
        const childTag = document.createElement('span');
        childTag.className = 'selected-teacher';
        childTag.style.fontSize = '12px';
        childTag.style.padding = '4px 8px';
        const childName = `${student.first_name} ${student.last_name}`;
        const childInfo = student.class_name ? ` (${student.class_name})` : '';
        childTag.textContent = childName + childInfo;
        childrenContainer.appendChild(childTag);
      });
      childrenCell.appendChild(childrenContainer);
    } else {
      childrenCell.textContent = '—';
    }
    
    // Status cell
    const statusCell = document.createElement('td');
    statusCell.className = 'teachers-table__cell';
    const statusBadge = document.createElement('span');
    if (isLocked) {
      statusBadge.textContent = 'Inactive';
      statusBadge.style.color = 'var(--state-error)';
      statusBadge.style.fontWeight = '500';
    } else {
      statusBadge.textContent = 'Active';
      statusBadge.style.color = 'var(--state-success)';
      statusBadge.style.fontWeight = '500';
    }
    statusCell.appendChild(statusBadge);
    
    // Actions cell
    const actionsCell = document.createElement('td');
    actionsCell.className = 'teachers-table__cell teachers-table__cell--actions';
    
    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'teachers-actions';
    
    const headmastersActionsDiv = document.createElement('div');
    headmastersActionsDiv.className = 'headmasters-actions';
    
    const details = document.createElement('details');
    details.className = 'headmasters-menu';
    
    const summary = document.createElement('summary');
    summary.setAttribute('aria-label', 'Open actions menu');
    const img = document.createElement('img');
    const buttonIconPath = (typeof window.PARENTS_ASSET_PATHS !== 'undefined' && window.PARENTS_ASSET_PATHS.buttonIcon) || '/assets/icons/social/S/button-3.svg';
    img.src = buttonIconPath;
    img.alt = '';
    img.setAttribute('data-theme-icon', 'true');
    summary.appendChild(img);
    
    const ul = document.createElement('ul');
    
    // Edit button
    const editLi = document.createElement('li');
    const editBtn = document.createElement('button');
    editBtn.type = 'button';
    editBtn.setAttribute('data-action', 'edit-parent');
    editBtn.setAttribute('data-parent-id', parentId);
    editBtn.setAttribute('data-parent-first-name', attrs.first_name || '');
    editBtn.setAttribute('data-parent-last-name', attrs.last_name || '');
    editBtn.setAttribute('data-parent-email', attrs.email || '');
    editBtn.setAttribute('data-parent-phone', attrs.phone || '');
    editBtn.setAttribute('data-parent-students', JSON.stringify(students));
    editBtn.textContent = 'Edit';
    editLi.appendChild(editBtn);
    
    // Resend invite button
    const resendLi = document.createElement('li');
    const resendBtn = document.createElement('button');
    resendBtn.type = 'button';
    resendBtn.setAttribute('data-action', 'resend-invite-parent');
    resendBtn.setAttribute('data-parent-id', parentId);
    resendBtn.setAttribute('data-parent-email', attrs.email || '');
    resendBtn.textContent = 'Resend invite';
    resendLi.appendChild(resendBtn);
    
    // Deactivate/Activate button
    const deactivateLi = document.createElement('li');
    const deactivateBtn = document.createElement('button');
    deactivateBtn.type = 'button';
    deactivateBtn.setAttribute('data-action', 'deactivate-parent');
    deactivateBtn.setAttribute('data-parent-id', parentId);
    deactivateBtn.setAttribute('data-parent-name', name);
    deactivateBtn.setAttribute('data-parent-is-locked', isLocked ? 'true' : 'false');
    deactivateBtn.textContent = isLocked ? 'Activate' : 'Deactivate';
    deactivateLi.appendChild(deactivateBtn);
    
    // Delete button
    const deleteLi = document.createElement('li');
    const deleteBtn = document.createElement('button');
    deleteBtn.type = 'button';
    deleteBtn.setAttribute('data-action', 'delete-parent');
    deleteBtn.setAttribute('data-parent-id', parentId);
    deleteBtn.setAttribute('data-parent-name', name);
    deleteBtn.textContent = 'Delete';
    deleteBtn.style.color = 'var(--state-error)';
    deleteLi.appendChild(deleteBtn);
    
    ul.appendChild(editLi);
    ul.appendChild(resendLi);
    ul.appendChild(deactivateLi);
    ul.appendChild(deleteLi);
    
    details.appendChild(summary);
    details.appendChild(ul);
    headmastersActionsDiv.appendChild(details);
    actionsDiv.appendChild(headmastersActionsDiv);
    actionsCell.appendChild(actionsDiv);
    
    row.appendChild(nameCell);
    row.appendChild(emailCell);
    row.appendChild(phoneCell);
    row.appendChild(childrenCell);
    row.appendChild(statusCell);
    row.appendChild(actionsCell);
    
    return row;
  }

  // Load parents from API
  async function loadParents(page = 1, searchTerm = '') {
    if (isLoading) return;
    isLoading = true;
    
    if (page === 1) {
      tbody.innerHTML = '';
      allParents = [];
      filteredParents = [];
    }
    
    loadingIndicator.style.display = 'block';
    emptyMessage.style.display = 'none';
    
    try {
      const params = new URLSearchParams({
        page: page.toString(),
        per_page: perPage.toString()
      });
      
      if (searchTerm) {
        params.append('search', searchTerm);
      }
      
      const result = await api.get(`${API_BASE}?${params.toString()}`);
      
      if (result.success && result.data) {
        const responseData = result.data;
        let parents = [];
        
        // Handle JSON:API format: {success: true, data: {data: [{id, type, attributes}]}}
        // Or: {success: true, data: [{id, type, attributes}]}
        if (responseData.data?.data && Array.isArray(responseData.data.data)) {
          parents = responseData.data.data;
        } else if (responseData.data && Array.isArray(responseData.data)) {
          parents = responseData.data;
        } else if (Array.isArray(responseData)) {
          parents = responseData;
        }
        
        const pagination = responseData.data?.pagination || responseData.pagination || {};
        
        // Filter out invalid parents before processing
        const validParents = parents.filter(parent => {
          if (!parent) return false;
          const attrs = parent.attributes || parent;
          const parentId = parent.id || attrs.id;
          return parentId && (attrs.first_name || attrs.last_name || attrs.email);
        });
        
        if (validParents.length > 0) {
          allParents = allParents.concat(validParents);
          filteredParents = allParents;
          
          validParents.forEach(parent => {
            const row = renderParentRow(parent);
            if (row) {
              tbody.appendChild(row);
            }
          });
          
          // Setup menu positioning after rendering (only once, menus are set up on initial load)
          if (page === 1) {
            setTimeout(() => setupParentMenus(), 0);
          }
          
          hasMore = pagination && pagination.has_more;
          currentPage = page;
        } else {
          hasMore = false;
        }
        
        if (allParents.length === 0) {
          emptyMessage.style.display = 'block';
        }
      } else {
        console.error('Failed to load parents:', result.error || result.errors);
        if (allParents.length === 0) {
          emptyMessage.style.display = 'block';
        }
      }
    } catch (error) {
      console.error('Error loading parents:', error);
      alert('Error loading parents: ' + error.message);
    } finally {
      isLoading = false;
      loadingIndicator.style.display = 'none';
    }
  }

  // Search functionality
  function handleSearch() {
    const searchTerm = searchInput.value.trim();
    currentSearchTerm = searchTerm;
    
    if (searchTimeout) {
      clearTimeout(searchTimeout);
    }
    
    searchTimeout = setTimeout(() => {
      if (searchTerm.length >= SEARCH_MIN_LENGTH || searchTerm.length === 0) {
        currentPage = 1;
        hasMore = true;
        isSearching = searchTerm.length >= SEARCH_MIN_LENGTH;
        loadParents(1, searchTerm);
      }
    }, 300);
  }

  // Infinite scroll
  function handleScroll() {
    if (isLoading || !hasMore) return;
    
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    const windowHeight = window.innerHeight;
    const documentHeight = document.documentElement.scrollHeight;
    
    if (scrollTop + windowHeight >= documentHeight - 200) {
      loadParents(currentPage + 1, currentSearchTerm);
    }
  }

  // Student autocomplete search
  async function searchStudents(searchTerm, mode) {
    if (!searchTerm || searchTerm.length < 2) {
      return [];
    }
    
    try {
      const params = new URLSearchParams({ q: searchTerm });
      const result = await api.get(`${API_BASE}/search_students?${params.toString()}`);
      
      if (result.success && result.data) {
        // Handle response format: {success: true, data: [...]} or {success: true, data: {data: [...]}}
        let responseData = result.data;
        
        // If nested success wrapper, unwrap it
        if (responseData.success && responseData.data) {
          responseData = responseData.data;
        }
        
        // Extract array from response
        // Could be: {data: [...]} or directly [...]
        let dataArray = responseData.data || responseData;
        
        // If it's an array, return it
        if (Array.isArray(dataArray)) {
          return dataArray;
        }
        
        // If it's a single object, wrap it in array
        if (dataArray && typeof dataArray === 'object') {
          return [dataArray];
        }
        
        return [];
      }
      return [];
    } catch (error) {
      console.error('Error searching students:', error);
      return [];
    }
  }

  // Render autocomplete dropdown
  function renderAutocomplete(students, mode) {
    const autocompleteId = mode === 'add' ? 'add-parent-students-autocomplete' : 'edit-parent-students-autocomplete';
    const autocomplete = document.getElementById(autocompleteId);
    if (!autocomplete) return;
    
    autocomplete.innerHTML = '';
    
    if (students.length === 0) {
      autocomplete.style.display = 'none';
      return;
    }
    
    students.forEach(student => {
      const item = document.createElement('div');
      item.className = 'autocomplete-item';
      item.style.cssText = 'padding: 8px 12px; cursor: pointer; border-bottom: 1px solid var(--border-contrast);';
      item.style.cssText += 'background: var(--surface-primary);';
      item.onmouseover = () => item.style.background = 'var(--surface-hover)';
      item.onmouseout = () => item.style.background = 'var(--surface-primary)';
      
      // Handle JSON:API format - extract attributes if needed
      const attrs = student.attributes || student;
      const name = `${attrs.first_name || ''} ${attrs.last_name || ''}`.trim();
      const classInfo = attrs.class_name ? ` • ${attrs.class_name}` : '';
      const birthdateInfo = attrs.birthdate ? ` • ${attrs.birthdate}` : '';
      
      item.innerHTML = `
        <div style="font-weight: 500;">${name}</div>
        <div style="font-size: 12px; color: var(--content-secondary);">${classInfo}${birthdateInfo}</div>
      `;
      
      item.onclick = () => {
        addStudent({
          id: student.id || attrs.id,
          first_name: attrs.first_name,
          last_name: attrs.last_name,
          class_name: attrs.class_name,
          birthdate: attrs.birthdate
        }, mode);
        autocomplete.style.display = 'none';
        const searchInput = document.getElementById(mode === 'add' ? 'add-parent-students-search' : 'edit-parent-students-search');
        if (searchInput) searchInput.value = '';
      };
      
      autocomplete.appendChild(item);
    });
    
    autocomplete.style.display = 'block';
  }

  // Add student to selected list
  function addStudent(student, mode) {
    const isAlreadySelected = selectedStudents[mode].some(s => s.id === student.id);
    if (isAlreadySelected) return;
    
    selectedStudents[mode].push(student);
    updateSelectedStudents(mode);
  }

  // Remove student from selected list
  function removeStudent(studentId, mode) {
    selectedStudents[mode] = selectedStudents[mode].filter(s => s.id !== studentId);
    updateSelectedStudents(mode);
  }

  // Update selected students display
  function updateSelectedStudents(mode) {
    const containerId = mode === 'add' ? 'add-parent-selected-students' : 'edit-parent-selected-students';
    const container = document.getElementById(containerId);
    if (!container) return;
    
    container.innerHTML = '';
    
    selectedStudents[mode].forEach(student => {
      const tag = document.createElement('span');
      tag.className = 'selected-teacher';
      tag.style.cssText = 'display: inline-flex; align-items: center; gap: 4px; padding: 4px 8px; margin: 4px; font-size: 12px;';
      tag.innerHTML = `
        ${student.first_name} ${student.last_name}${student.class_name ? ` (${student.class_name})` : ''}
        <button type="button" style="background: none; border: none; cursor: pointer; padding: 0; margin-left: 4px; color: var(--content-secondary);" onclick="this.parentElement.remove(); window.removeParentStudent('${student.id}', '${mode}')">×</button>
      `;
      container.appendChild(tag);
    });
  }

  // Make removeStudent available globally for onclick handlers
  window.removeParentStudent = removeStudent;

  // Setup autocomplete for add form
  const addSearchInput = document.getElementById('add-parent-students-search');
  if (addSearchInput) {
    addSearchInput.addEventListener('input', (e) => {
      const searchTerm = e.target.value.trim();
      
      if (autocompleteTimeout) {
        clearTimeout(autocompleteTimeout);
      }
      
      autocompleteTimeout = setTimeout(async () => {
        if (searchTerm.length >= 2) {
          const students = await searchStudents(searchTerm, 'add');
          renderAutocomplete(students, 'add');
        } else {
          const autocomplete = document.getElementById('add-parent-students-autocomplete');
          if (autocomplete) autocomplete.style.display = 'none';
        }
      }, 300);
    });
  }

  // Setup autocomplete for edit form
  const editSearchInput = document.getElementById('edit-parent-students-search');
  if (editSearchInput) {
    editSearchInput.addEventListener('input', (e) => {
      const searchTerm = e.target.value.trim();
      
      if (autocompleteTimeout) {
        clearTimeout(autocompleteTimeout);
      }
      
      autocompleteTimeout = setTimeout(async () => {
        if (searchTerm.length >= 2) {
          const students = await searchStudents(searchTerm, 'edit');
          renderAutocomplete(students, 'edit');
        } else {
          const autocomplete = document.getElementById('edit-parent-students-autocomplete');
          if (autocomplete) autocomplete.style.display = 'none';
        }
      }, 300);
    });
  }

  // Handle edit parent click
  async function handleEditParentClick(e) {
    const btn = e.target.closest('[data-action="edit-parent"]');
    if (!btn) return;
    
    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();
    
    const parentId = btn.getAttribute('data-parent-id');
    if (!parentId) {
      console.error('Error: Parent ID is missing');
      return;
    }
    
    const modal = document.getElementById('edit-parent-modal');
    const firstNameField = document.getElementById('edit-parent-first-name');
    const lastNameField = document.getElementById('edit-parent-last-name');
    const emailField = document.getElementById('edit-parent-email');
    const phoneField = document.getElementById('edit-parent-phone');
    const relationField = document.getElementById('edit-parent-relation');
    
    // Set parent ID
    const parentIdField = document.getElementById('edit-parent-id');
    if (parentIdField) parentIdField.value = parentId;
    
    // Clear form fields initially
    if (firstNameField) firstNameField.value = '';
    if (lastNameField) lastNameField.value = '';
    if (emailField) emailField.value = '';
    if (phoneField) phoneField.value = '';
    if (relationField) relationField.value = 'other';
    
    // Clear selected students
    selectedStudents.edit = [];
    updateSelectedStudents('edit');
    
    // Open modal first
    if (modal) {
      modal.setAttribute('aria-hidden', 'false');
      modal.classList.add('is-open');
    }
    
    // Fetch full parent data from API
    try {
      const result = await api.get(`${API_BASE}/${parentId}`);
      
      if (result.success && result.data) {
        let responseData = result.data;
        
        // If responseData has nested success wrapper, unwrap it
        if (responseData.success && responseData.data) {
          responseData = responseData.data;
        }
        
        // JSON:API format: {data: {id, type, attributes}}
        const jsonApiResource = responseData.data || responseData;
        
        // Get attributes from JSON:API resource
        const attributes = jsonApiResource.attributes || jsonApiResource;
        
        if (attributes) {
          if (firstNameField) firstNameField.value = attributes.first_name || '';
          if (lastNameField) lastNameField.value = attributes.last_name || '';
          if (emailField) emailField.value = attributes.email || '';
          if (phoneField) phoneField.value = attributes.phone || '';
          
          // Load students from attributes.students
          const students = Array.isArray(attributes.students) ? attributes.students : [];
          selectedStudents.edit = students.map(s => ({
            id: s.id,
            first_name: s.first_name,
            last_name: s.last_name,
            class_name: s.class_name,
            birthdate: s.birthdate
          }));
          updateSelectedStudents('edit');
          
          // Set relation from first student's relation (if exists)
          if (relationField && students.length > 0 && students[0].relation) {
            relationField.value = students[0].relation;
          }
        }
      }
    } catch (error) {
      console.error('Error fetching parent data:', error);
    }
    
    const menu = btn.closest('.headmasters-menu');
    if (menu) menu.open = false;
  }

  // Handle add parent form submission
  const addForm = document.getElementById('add-parent-form');
  if (addForm) {
    addForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const submitBtn = addForm.querySelector('button[type="submit"]');
      const originalText = submitBtn.textContent;
      submitBtn.disabled = true;
      submitBtn.textContent = 'Adding...';
      
      const data = {
        parent: {
          first_name: document.getElementById('add-parent-first-name').value,
          last_name: document.getElementById('add-parent-last-name').value,
          email: document.getElementById('add-parent-email').value,
          phone: document.getElementById('add-parent-phone').value,
          relation: document.getElementById('add-parent-relation').value,
          student_ids: selectedStudents.add.map(s => s.id)
        }
      };
      
      try {
        const result = await api.post(API_BASE, data);
        
        if (result.success) {
          // Close modal and reset form
          const modal = document.getElementById('add-parent-modal');
          if (modal) {
            modal.setAttribute('aria-hidden', 'true');
            modal.classList.remove('is-open');
          }
          addForm.reset();
          selectedStudents.add = [];
          updateSelectedStudents('add');
          
          // Reload parents list
          currentPage = 1;
          hasMore = true;
          loadParents(1, currentSearchTerm);
        } else {
          const errorMessage = Array.isArray(result.errors) ? result.errors.join(', ') : (result.error || 'Failed to add parent');
          alert('Error: ' + errorMessage);
        }
      } catch (error) {
        console.error('Error adding parent:', error);
        alert('Error: ' + (error.message || 'Failed to add parent'));
      } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = originalText;
      }
    });
  }

  // Handle edit parent form submission
  const editForm = document.getElementById('edit-parent-form');
  if (editForm) {
    editForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const parentId = document.getElementById('edit-parent-id').value;
      const submitBtn = editForm.querySelector('button[type="submit"]');
      const originalText = submitBtn.textContent;
      submitBtn.disabled = true;
      submitBtn.textContent = 'Saving...';
      
      const data = {
        parent: {
          first_name: document.getElementById('edit-parent-first-name').value,
          last_name: document.getElementById('edit-parent-last-name').value,
          email: document.getElementById('edit-parent-email').value,
          phone: document.getElementById('edit-parent-phone').value,
          relation: document.getElementById('edit-parent-relation').value,
          student_ids: selectedStudents.edit.map(s => s.id)
        }
      };
      
      try {
        const result = await api.patch(`${API_BASE}/${parentId}`, data);
        
        if (result.success) {
          // Close modal and reset form
          const modal = document.getElementById('edit-parent-modal');
          if (modal) {
            modal.setAttribute('aria-hidden', 'true');
            modal.classList.remove('is-open');
          }
          editForm.reset();
          selectedStudents.edit = [];
          updateSelectedStudents('edit');
          
          // Reload parents list
          currentPage = 1;
          hasMore = true;
          loadParents(1, currentSearchTerm);
        } else {
          const errorMessage = Array.isArray(result.errors) ? result.errors.join(', ') : (result.error || 'Failed to update parent');
          alert('Error: ' + errorMessage);
        }
      } catch (error) {
        console.error('Error updating parent:', error);
        alert('Error: ' + (error.message || 'Failed to update parent'));
      } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = originalText;
      }
    });
  }

  // Handle delete parent
  let deleteParentId = null;
  
  function handleDeleteParent(e) {
    const btn = e.target.closest('[data-action="delete-parent"]');
    if (!btn) return;
    
    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();
    
    deleteParentId = btn.getAttribute('data-parent-id');
    const name = btn.getAttribute('data-parent-name') || '';
    
    const deleteNameEl = document.querySelector('[data-delete-name]');
    if (deleteNameEl) {
      deleteNameEl.textContent = name;
    }
    
    const confirmBtn = document.getElementById('delete-parent-confirm-btn');
    if (confirmBtn) {
      confirmBtn.disabled = false;
      confirmBtn.removeAttribute('aria-disabled');
    }
    
    const menu = btn.closest('.headmasters-menu');
    if (menu) menu.open = false;
    
    const deleteModal = document.getElementById('delete-parent-modal');
    if (deleteModal) {
      deleteModal.setAttribute('aria-hidden', 'false');
      deleteModal.classList.add('is-open');
    }
  }

  // Handle deactivate/activate parent
  let deactivateParentId = null;
  
  function handleDeactivateParent(e) {
    const btn = e.target.closest('[data-action="deactivate-parent"]');
    if (!btn) return;
    
    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();
    
    deactivateParentId = btn.getAttribute('data-parent-id');
    const name = btn.getAttribute('data-parent-name') || '';
    const isLocked = btn.getAttribute('data-parent-is-locked') === 'true';
    
    const deactivateNameEl = document.querySelector('[data-deactivate-name]');
    if (deactivateNameEl) {
      deactivateNameEl.textContent = name;
    }
    
    const modalTitle = document.getElementById('deactivate-parent-title');
    const modalMessage = document.getElementById('deactivate-parent-message');
    const confirmBtn = document.getElementById('deactivate-parent-confirm-btn');
    
    if (confirmBtn) {
      confirmBtn.disabled = false;
      confirmBtn.removeAttribute('aria-disabled');
    }
    
    if (isLocked) {
      if (modalTitle) modalTitle.textContent = 'Activate parent';
      if (modalMessage) modalMessage.innerHTML = `Are you sure you want to activate <strong>${name}</strong>? They will regain access immediately.`;
      if (confirmBtn) {
        confirmBtn.textContent = 'Activate';
        confirmBtn.classList.remove('schools-modal__primary--danger');
      }
    } else {
      if (modalTitle) modalTitle.textContent = 'Deactivate parent';
      if (modalMessage) modalMessage.innerHTML = `Are you sure you want to deactivate <strong>${name}</strong>? They will lose access immediately.`;
      if (confirmBtn) {
        confirmBtn.textContent = 'Deactivate';
        confirmBtn.classList.add('schools-modal__primary--danger');
      }
    }
    
    const menu = btn.closest('.headmasters-menu');
    if (menu) menu.open = false;
    
    const deactivateModal = document.getElementById('deactivate-parent-modal');
    if (deactivateModal) {
      deactivateModal.setAttribute('aria-hidden', 'false');
      deactivateModal.classList.add('is-open');
    }
  }

  // Handle resend invite
  async function handleResendInvite(e) {
    const btn = e.target.closest('[data-action="resend-invite-parent"]');
    if (!btn) return;
    
    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();
    
    const parentId = btn.getAttribute('data-parent-id');
    
    if (!parentId) {
      console.error('Error: Parent ID is missing');
      return;
    }
    
    const originalText = btn.textContent;
    btn.disabled = true;
    btn.textContent = 'Sending...';
    
    try {
      const result = await api.post(`${API_BASE}/${parentId}/resend_invite`, {});
      
      if (result.success) {
        btn.textContent = 'Sent!';
        btn.style.color = 'var(--state-success)';
        
        const menu = btn.closest('.headmasters-menu');
        if (menu) menu.open = false;
        
        setTimeout(() => {
          btn.disabled = false;
          btn.textContent = originalText;
          btn.style.color = '';
        }, 2000);
      } else {
        console.error('Error:', result.error || 'Failed to resend invite');
        btn.disabled = false;
        btn.textContent = originalText;
      }
    } catch (error) {
      console.error('Resend invite error:', error);
      btn.disabled = false;
      btn.textContent = originalText;
    }
  }

  // Handle parent menu positioning (same as teachers/administrations)
  function setupParentMenus() {
    const menus = document.querySelectorAll('.headmasters-menu');
    const tbody = document.querySelector('.teachers-table__body');
    if (!tbody) return;

    menus.forEach((menu) => {
      // Skip if already has toggle listener
      if (menu.dataset.menuSetup === 'true') return;
      menu.dataset.menuSetup = 'true';
      
      const summary = menu.querySelector('summary');
      if (!summary) return;

      menu.addEventListener('toggle', function() {
        if (menu.open) {
          menus.forEach(m => {
            if (m !== menu && m.open) {
              m.open = false;
            }
          });

          requestAnimationFrame(() => {
            const summaryRect = summary.getBoundingClientRect();
            const ul = menu.querySelector('ul');
            if (!ul) return;

            const ulHeight = ul.offsetHeight || 150;
            const spaceBelow = window.innerHeight - summaryRect.bottom;
            const spaceAbove = summaryRect.top;
            const row = menu.closest('tr');
            const rows = Array.from(tbody.querySelectorAll('tr'));
            const rowIndex = rows.indexOf(row);
            const totalRows = rows.length;

            ul.style.position = 'fixed';
            ul.style.zIndex = '999999';
            ul.style.isolation = 'isolate';
            ul.style.transform = 'translateZ(0)';
            ul.style.willChange = 'transform';
            
            if (totalRows === 1) {
              menu.removeAttribute('data-menu-align');
              ul.style.top = (summaryRect.bottom + 10) + 'px';
              ul.style.right = (window.innerWidth - summaryRect.right) + 'px';
              ul.style.bottom = 'auto';
            } else if (spaceBelow < ulHeight + 20 && spaceAbove > ulHeight + 20 && rowIndex >= totalRows - 2) {
              menu.setAttribute('data-menu-align', 'top');
              ul.style.bottom = (window.innerHeight - summaryRect.top + 10) + 'px';
              ul.style.right = (window.innerWidth - summaryRect.right) + 'px';
              ul.style.top = 'auto';
            } else {
              menu.removeAttribute('data-menu-align');
              ul.style.top = (summaryRect.bottom + 10) + 'px';
              ul.style.right = (window.innerWidth - summaryRect.right) + 'px';
              ul.style.bottom = 'auto';
            }
          });
        } else {
          const ul = menu.querySelector('ul');
          if (ul) {
            ul.style.position = '';
            ul.style.top = '';
            ul.style.bottom = '';
            ul.style.right = '';
            ul.style.zIndex = '';
            ul.style.transform = '';
            ul.style.willChange = '';
          }
        }
      });

      const ul = menu.querySelector('ul');
      if (ul) {
        ul.addEventListener('click', function(e) {
          // Only stop propagation for clicks on the ul itself, not on buttons
          if (e.target === ul) {
            e.stopPropagation();
          }
        });
      }
    });

    let clickHandler = function(e) {
      if (!e.target.closest('.headmasters-menu')) {
        menus.forEach(m => {
          if (m.open) {
            m.open = false;
          }
        });
      }
    };
    
    document.removeEventListener('click', clickHandler, true);
    document.addEventListener('click', clickHandler, true);
  }

  // Close autocomplete when clicking outside
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.student-select-wrapper')) {
      document.querySelectorAll('.student-autocomplete').forEach(el => {
        el.style.display = 'none';
      });
    }
  });

  // Modal handlers
  document.querySelectorAll('[data-open-modal]').forEach(btn => {
    btn.addEventListener('click', () => {
      const modalId = btn.getAttribute('data-open-modal');
      const modal = document.getElementById(modalId);
      if (modal) {
        modal.setAttribute('aria-hidden', 'false');
        modal.classList.add('is-open');
      }
    });
  });

  document.querySelectorAll('[data-close-modal]').forEach(btn => {
    btn.addEventListener('click', () => {
      const modalId = btn.getAttribute('data-close-modal');
      const modal = document.getElementById(modalId);
      if (modal) {
        modal.setAttribute('aria-hidden', 'true');
        modal.classList.remove('is-open');
      }
    });
  });

  // Close modal on overlay click
  document.querySelectorAll('.schools-modal__overlay').forEach(overlay => {
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        const modal = overlay.closest('.schools-modal');
        if (modal) {
          modal.setAttribute('aria-hidden', 'true');
          modal.classList.remove('is-open');
        }
      }
    });
  });

  // Deactivate parent confirm handler
  const deactivateConfirmBtn = document.getElementById('deactivate-parent-confirm-btn');
  if (deactivateConfirmBtn) {
    deactivateConfirmBtn.addEventListener('click', async () => {
      if (!deactivateParentId) return;
      
      const originalText = deactivateConfirmBtn.textContent;
      deactivateConfirmBtn.disabled = true;
      deactivateConfirmBtn.textContent = 'Processing...';
      
      try {
        const result = await api.post(`${API_BASE}/${deactivateParentId}/lock`, {});
        
        if (result.success) {
          const modal = document.getElementById('deactivate-parent-modal');
          if (modal) {
            const focusedElement = modal.querySelector(':focus');
            if (focusedElement) focusedElement.blur();
            modal.setAttribute('aria-hidden', 'true');
            modal.classList.remove('is-open');
          }
          
          // Reload parents list
          currentPage = 1;
          hasMore = true;
          loadParents(1, currentSearchTerm);
        } else {
          alert('Error: ' + String(result.error || 'Failed to update parent status'));
          deactivateConfirmBtn.disabled = false;
          deactivateConfirmBtn.textContent = originalText;
        }
      } catch (error) {
        console.error('Deactivate error:', error);
        alert('Error: ' + String(error.message || 'Unknown error'));
        deactivateConfirmBtn.disabled = false;
        deactivateConfirmBtn.textContent = originalText;
      }
    });
  }
  
  // Delete parent confirm handler
  const deleteConfirmBtn = document.getElementById('delete-parent-confirm-btn');
  if (deleteConfirmBtn) {
    deleteConfirmBtn.addEventListener('click', async () => {
      if (!deleteParentId) return;
      
      const originalText = deleteConfirmBtn.textContent;
      deleteConfirmBtn.disabled = true;
      deleteConfirmBtn.textContent = 'Deleting...';
      
      try {
        const result = await api.delete(`${API_BASE}/${deleteParentId}`);
        
        if (result.success) {
          const modal = document.getElementById('delete-parent-modal');
          if (modal) {
            const focusedElement = modal.querySelector(':focus');
            if (focusedElement) focusedElement.blur();
            modal.setAttribute('aria-hidden', 'true');
            modal.classList.remove('is-open');
          }
          
          // Reload parents list
          currentPage = 1;
          hasMore = true;
          loadParents(1, currentSearchTerm);
        } else {
          const errorMessage = Array.isArray(result.errors) ? result.errors.join(', ') : (result.error || 'Failed to delete parent');
          alert('Error: ' + errorMessage);
          deleteConfirmBtn.disabled = false;
          deleteConfirmBtn.textContent = originalText;
        }
      } catch (error) {
        console.error('Delete error:', error);
        alert('Error: ' + (error.message || 'Failed to delete parent'));
        deleteConfirmBtn.disabled = false;
        deleteConfirmBtn.textContent = originalText;
      }
    });
  }

  // Event listeners
  searchInput.addEventListener('input', handleSearch);
  window.addEventListener('scroll', handleScroll);
  tbody.addEventListener('click', (e) => {
    handleEditParentClick(e);
    handleDeleteParent(e);
    handleDeactivateParent(e);
    handleResendInvite(e);
  });
  
  // Load initial data
  loadParents(1);
});

