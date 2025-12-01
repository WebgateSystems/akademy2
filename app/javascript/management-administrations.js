// Management Administrations page JavaScript
document.addEventListener('DOMContentLoaded', function() {
  // Check if we're on the administrations page
  if (!document.getElementById('administrations-table-body')) {
    return;
  }

  // Infinite scroll implementation
  let currentPage = 1;
  let isLoading = false;
  let hasMore = true;
  let allAdministrations = [];
  let filteredAdministrations = [];
  let isSearching = false;
  let currentSearchTerm = '';
  let searchTimeout = null;
  const perPage = 20;
  const SEARCH_MIN_LENGTH = 3;
  const tbody = document.getElementById('administrations-table-body');
  const loadingIndicator = document.getElementById('administrations-loading-indicator');
  const emptyMessage = document.getElementById('administrations-empty-message');
  const searchInput = document.getElementById('administrations-search-input');
  const CURRENT_USER_ID = window.CURRENT_USER_ID;

  if (typeof window.ApiClient === 'undefined') {
    console.error('ApiClient not available. Make sure api_client.js is loaded.');
    return;
  }

  const api = new window.ApiClient();
  const API_BASE = '/management/administrations';

  // Function to render an administration row
  function renderAdministrationRow(administration) {
    const attrs = administration.attributes || administration;
    const name = [attrs.first_name, attrs.last_name].filter(Boolean).join(' ') || attrs.email;
    const roles = attrs.roles || [];
    const email = attrs.email || '—';
    const phone = attrs.phone || '—';
    const administrationId = administration.id || attrs.id;
    const isCurrentUser = String(administrationId) === String(CURRENT_USER_ID);

    const row = document.createElement('tr');
    row.className = 'teachers-table__row';
    if (isCurrentUser) {
      row.style.backgroundColor = 'var(--surface-hover, rgba(0, 0, 0, 0.05))';
      row.style.fontWeight = '500';
    }
    
    const isLocked = attrs.is_locked || attrs.locked_at;
    
    // Name cell
    const nameCell = document.createElement('td');
    nameCell.className = 'teachers-table__cell';
    nameCell.textContent = name;
    if (isCurrentUser) {
      nameCell.innerHTML = name + ' <span style="color: var(--content-secondary); font-size: 0.9em;">(You)</span>';
    }
    
    // Roles cell
    const rolesCell = document.createElement('td');
    rolesCell.className = 'teachers-table__cell';
    if (roles.length > 0) {
      const rolesContainer = document.createElement('div');
      rolesContainer.style.display = 'flex';
      rolesContainer.style.gap = '8px';
      rolesContainer.style.flexWrap = 'wrap';
      roles.forEach(role => {
        const roleTag = document.createElement('span');
        roleTag.className = 'selected-teacher';
        roleTag.style.fontSize = '12px';
        roleTag.style.padding = '4px 8px';
        let roleName = 'Unknown';
        if (role === 'principal') {
          roleName = 'Principal';
        } else if (role === 'school_manager') {
          roleName = 'School Manager';
        } else if (role === 'teacher') {
          roleName = 'Teacher';
        }
        roleTag.textContent = roleName;
        rolesContainer.appendChild(roleTag);
      });
      rolesCell.appendChild(rolesContainer);
    } else {
      rolesCell.textContent = '—';
    }
    
    // Email and Phone cells
    const emailCell = document.createElement('td');
    emailCell.className = 'teachers-table__cell';
    emailCell.textContent = email;
    
    const phoneCell = document.createElement('td');
    phoneCell.className = 'teachers-table__cell';
    phoneCell.textContent = phone;
    
    // Create cells array
    const cells = [nameCell, rolesCell, emailCell, phoneCell];
    
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
    
    const administrationsActionsDiv = document.createElement('div');
    administrationsActionsDiv.className = 'teachers-actions';
    
    const headmastersActionsDiv = document.createElement('div');
    headmastersActionsDiv.className = 'headmasters-actions';
    
    const details = document.createElement('details');
    details.className = 'headmasters-menu';
    
    const summary = document.createElement('summary');
    summary.setAttribute('aria-label', 'Open actions menu');
    const img = document.createElement('img');
    const buttonIconPath = (typeof window.ADMINISTRATIONS_ASSET_PATHS !== 'undefined' && window.ADMINISTRATIONS_ASSET_PATHS.buttonIcon) || '/assets/icons/social/S/button-3.svg';
    img.src = buttonIconPath;
    img.alt = '';
    img.setAttribute('data-theme-icon', 'true');
    summary.appendChild(img);
    
    const ul = document.createElement('ul');
    
    // Edit button
    const editLi = document.createElement('li');
    const editBtn = document.createElement('button');
    editBtn.type = 'button';
    editBtn.setAttribute('data-action', 'edit-administration');
    editBtn.setAttribute('data-administration-id', administrationId);
    editBtn.setAttribute('data-administration-first-name', attrs.first_name || '');
    editBtn.setAttribute('data-administration-last-name', attrs.last_name || '');
    editBtn.setAttribute('data-administration-email', attrs.email || '');
    editBtn.setAttribute('data-administration-phone', attrs.phone || '');
    editBtn.setAttribute('data-administration-roles', JSON.stringify(roles));
    editBtn.textContent = 'Edit';
    editLi.appendChild(editBtn);
    
    // Resend invite button
    const resendLi = document.createElement('li');
    const resendBtn = document.createElement('button');
    resendBtn.type = 'button';
    resendBtn.setAttribute('data-action', 'resend-invite');
    resendBtn.setAttribute('data-administration-id', administrationId);
    resendBtn.setAttribute('data-administration-email', attrs.email || '');
    resendBtn.textContent = 'Resend invite';
    resendLi.appendChild(resendBtn);
    
    // Deactivate/Activate button (disabled for current user)
    const deactivateLi = document.createElement('li');
    const deactivateBtn = document.createElement('button');
    deactivateBtn.type = 'button';
    deactivateBtn.setAttribute('data-action', 'deactivate-administration');
    deactivateBtn.setAttribute('data-administration-id', administrationId);
    deactivateBtn.setAttribute('data-administration-name', name);
    deactivateBtn.setAttribute('data-administration-is-locked', isLocked ? 'true' : 'false');
    deactivateBtn.textContent = isLocked ? 'Activate' : 'Deactivate';
    if (isCurrentUser) {
      deactivateBtn.disabled = true;
      deactivateBtn.style.opacity = '0.5';
      deactivateBtn.style.cursor = 'not-allowed';
      deactivateBtn.title = 'You cannot deactivate your own account';
    }
    deactivateLi.appendChild(deactivateBtn);
    
    // Delete button (disabled for current user)
    const deleteLi = document.createElement('li');
    const deleteBtn = document.createElement('button');
    deleteBtn.type = 'button';
    deleteBtn.setAttribute('data-action', 'delete-administration');
    deleteBtn.setAttribute('data-administration-id', administrationId);
    deleteBtn.setAttribute('data-administration-name', name);
    deleteBtn.textContent = 'Delete';
    deleteBtn.style.color = 'var(--state-error)';
    if (isCurrentUser) {
      deleteBtn.disabled = true;
      deleteBtn.style.opacity = '0.5';
      deleteBtn.style.cursor = 'not-allowed';
      deleteBtn.title = 'You cannot delete your own account';
    }
    deleteLi.appendChild(deleteBtn);
    
    ul.appendChild(editLi);
    ul.appendChild(resendLi);
    ul.appendChild(deactivateLi);
    ul.appendChild(deleteLi);
    
    details.appendChild(summary);
    details.appendChild(ul);
    headmastersActionsDiv.appendChild(details);
    administrationsActionsDiv.appendChild(headmastersActionsDiv);
    
    actionsCell.appendChild(administrationsActionsDiv);
    
    cells.forEach(cell => row.appendChild(cell));
    row.appendChild(statusCell);
    row.appendChild(actionsCell);
    
    return row;
  }

  // Function to load administrations from API
  async function loadAdministrations(page = 1, searchTerm = '') {
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
        let administrations = [];
        
        if (responseData.data?.data && Array.isArray(responseData.data.data)) {
          administrations = responseData.data.data;
        } else if (responseData.data && Array.isArray(responseData.data)) {
          administrations = responseData.data;
        } else if (Array.isArray(responseData)) {
          administrations = responseData;
        }
        
        const pagination = responseData.data?.pagination || responseData.pagination || {};

        if (page === 1) {
          allAdministrations = [];
          tbody.innerHTML = '';
        }

        allAdministrations = allAdministrations.concat(administrations);
        filteredAdministrations = allAdministrations;

        administrations.forEach(administration => {
          const row = renderAdministrationRow(administration);
          if (row) {
            tbody.appendChild(row);
          }
        });

        hasMore = pagination.has_more || false;
        currentPage = page;

        if (allAdministrations.length === 0) {
          emptyMessage.style.display = 'block';
        } else {
          emptyMessage.style.display = 'none';
        }

        setupAdministrationMenus();
        setupEditAdministrationHandler();
        setupResendInviteHandler();
        setupDeactivateAdministrationHandler();
        setupDeleteAdministrationHandler();
      } else {
        console.error('Failed to load administrations:', result);
        if (result.error) {
          alert('Error loading administrations: ' + result.error);
        }
        emptyMessage.style.display = 'block';
      }
    } catch (error) {
      console.error('Error loading administrations:', error);
      alert('Error loading administrations: ' + error.message);
      emptyMessage.style.display = 'block';
    } finally {
      isLoading = false;
      loadingIndicator.style.display = 'none';
    }
  }

  // Infinite scroll handler
  function handleScroll() {
    if (isLoading || !hasMore) return;
    
    if (isSearching && currentSearchTerm.length < SEARCH_MIN_LENGTH) {
      return;
    }

    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    const windowHeight = window.innerHeight;
    const documentHeight = document.documentElement.scrollHeight;

    if (scrollTop + windowHeight >= documentHeight - 200) {
      loadAdministrations(currentPage + 1, currentSearchTerm);
    }
  }

  let scrollTimeout;
  window.addEventListener('scroll', function() {
    if (scrollTimeout) {
      clearTimeout(scrollTimeout);
    }
    scrollTimeout = setTimeout(handleScroll, 100);
  });

  // Search/filter functionality
  if (searchInput) {
    searchInput.addEventListener('input', function() {
      const searchTerm = this.value.trim();
      currentSearchTerm = searchTerm;
      
      if (searchTimeout) {
        clearTimeout(searchTimeout);
      }

      if (!searchTerm) {
        isSearching = false;
        currentPage = 1;
        hasMore = true;
        allAdministrations = [];
        tbody.innerHTML = '';
        loadAdministrations(1);
        return;
      }

      if (searchTerm.length >= SEARCH_MIN_LENGTH) {
        isSearching = true;
        searchTimeout = setTimeout(() => {
          currentPage = 1;
          hasMore = true;
          allAdministrations = [];
          tbody.innerHTML = '';
          loadAdministrations(1, searchTerm);
        }, 300);
      } else {
        isSearching = true;
        const searchTermLower = searchTerm.toLowerCase();
        
        filteredAdministrations = allAdministrations.filter(administration => {
          const attrs = administration.attributes || administration;
          const name = [attrs.first_name, attrs.last_name].filter(Boolean).join(' ').toLowerCase() || (attrs.email || '').toLowerCase();
          const email = (attrs.email || '').toLowerCase();
          const phone = (attrs.phone || '').toLowerCase();
          const isLocked = attrs.is_locked || attrs.locked_at;
          const status = isLocked ? 'inactive' : 'active';

          return name.includes(searchTermLower) ||
                 email.includes(searchTermLower) ||
                 phone.includes(searchTermLower) ||
                 status.includes(searchTermLower);
        });

        tbody.innerHTML = '';
        filteredAdministrations.forEach(administration => {
          tbody.appendChild(renderAdministrationRow(administration));
        });

        if (filteredAdministrations.length === 0) {
          emptyMessage.style.display = 'block';
        } else {
          emptyMessage.style.display = 'none';
        }

        setupAdministrationMenus();
      }
    });
  }

  // Delete administration handler
  let deleteAdministrationId = null;
  
  function setupDeleteAdministrationHandler() {
    if (tbody) {
      tbody.removeEventListener('click', handleDeleteAdministrationClick, true);
      tbody.addEventListener('click', handleDeleteAdministrationClick, true);
    }
  }

  function handleDeleteAdministrationClick(e) {
    const btn = e.target.closest('[data-action="delete-administration"]');
    if (!btn) return;

    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();

    deleteAdministrationId = btn.getAttribute('data-administration-id');
    const name = btn.getAttribute('data-administration-name') || '';
    
    if (!confirm(`Are you sure you want to delete ${name}? This action cannot be undone.`)) {
      return;
    }

    const originalText = btn.textContent;
    btn.disabled = true;
    btn.textContent = 'Deleting...';

    (async () => {
      try {
        const result = await api.delete(`${API_BASE}/${deleteAdministrationId}`);
        
        if (result.success) {
          const menu = btn.closest('.headmasters-menu');
          if (menu) menu.open = false;
          
          allAdministrations = [];
          currentPage = 1;
          hasMore = true;
          await loadAdministrations(1, currentSearchTerm);
        } else {
          alert('Error: ' + String(result.error || 'Failed to delete administration'));
          btn.disabled = false;
          btn.textContent = originalText;
        }
      } catch (error) {
        console.error('Delete error:', error);
        alert('Error: ' + String(error.message || 'Unknown error'));
        btn.disabled = false;
        btn.textContent = originalText;
      }
    })();
  }

  // Handle administration menu positioning
  function setupAdministrationMenus() {
    const menus = document.querySelectorAll('.headmasters-menu');
    const tbody = document.querySelector('.teachers-table__body');
    if (!tbody) return;

    menus.forEach((menu) => {
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
          e.stopPropagation();
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
    
    document.addEventListener('click', clickHandler, true);
  }

  setupAdministrationMenus();

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
        const focusedElement = modal.querySelector(':focus');
        if (focusedElement) {
          focusedElement.blur();
        }
        
        if (modalId === 'deactivate-administration-modal') {
          const confirmBtn = document.getElementById('deactivate-administration-confirm-btn');
          if (confirmBtn) {
            confirmBtn.disabled = false;
            confirmBtn.removeAttribute('aria-disabled');
            confirmBtn.textContent = 'Deactivate';
          }
          deactivateAdministrationId = null;
        }
        
        modal.setAttribute('aria-hidden', 'true');
        modal.classList.remove('is-open');
      }
    });
  });

  document.querySelectorAll('.schools-modal__overlay').forEach(overlay => {
    overlay.addEventListener('click', function() {
      const modal = this.closest('.schools-modal');
      if (modal) {
        const focusedElement = modal.querySelector(':focus');
        if (focusedElement) {
          focusedElement.blur();
        }
        
        if (modal.id === 'deactivate-administration-modal') {
          const confirmBtn = document.getElementById('deactivate-administration-confirm-btn');
          if (confirmBtn) {
            confirmBtn.disabled = false;
            confirmBtn.removeAttribute('aria-disabled');
            confirmBtn.textContent = 'Deactivate';
          }
          deactivateAdministrationId = null;
        }
        
        modal.setAttribute('aria-hidden', 'true');
        modal.classList.remove('is-open');
      }
    });
  });

  // Edit administration button handler
  function setupEditAdministrationHandler() {
    if (tbody) {
      tbody.removeEventListener('click', handleEditAdministrationClick, true);
      tbody.addEventListener('click', handleEditAdministrationClick, true);
    }
  }

  async function handleEditAdministrationClick(e) {
    const btn = e.target.closest('[data-action="edit-administration"]');
    if (!btn) return;

    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();

    const modal = document.getElementById('edit-administration-modal');
    if (!modal) {
      console.error('Edit administration modal not found');
      return;
    }

    const administrationId = btn.getAttribute('data-administration-id');
    if (!administrationId) {
      console.error('Administration ID not found');
      return;
    }

    const firstName = btn.getAttribute('data-administration-first-name') || '';
    const lastName = btn.getAttribute('data-administration-last-name') || '';
    const email = btn.getAttribute('data-administration-email') || '';
    const phone = btn.getAttribute('data-administration-phone') || '';
    const rolesJson = btn.getAttribute('data-administration-roles') || '[]';
    let roles = [];
    try {
      roles = JSON.parse(rolesJson);
    } catch (e) {
      console.error('Failed to parse roles:', e);
    }

    const idField = document.getElementById('edit-administration-id');
    if (idField) idField.value = administrationId || '';

    const firstNameField = document.getElementById('edit-administration-first-name');
    if (firstNameField) firstNameField.value = firstName;

    const lastNameField = document.getElementById('edit-administration-last-name');
    if (lastNameField) lastNameField.value = lastName;

    const emailField = document.getElementById('edit-administration-email');
    if (emailField) emailField.value = email;

    const phoneField = document.getElementById('edit-administration-phone');
    if (phoneField) phoneField.value = phone;

    // Set role checkboxes
    const principalCheckbox = document.getElementById('edit-administration-role-principal');
    const schoolManagerCheckbox = document.getElementById('edit-administration-role-school-manager');
    const teacherCheckbox = document.getElementById('edit-administration-role-teacher');
    
    // Remove any existing warning message
    const existingWarning = document.querySelector('#edit-administration-modal .role-warning');
    if (existingWarning) {
      existingWarning.remove();
    }
    
    // Check if editing own account - disable role checkboxes
    const isCurrentUser = String(administrationId) === String(CURRENT_USER_ID);
    if (isCurrentUser) {
      if (principalCheckbox) {
        principalCheckbox.disabled = true;
        principalCheckbox.setAttribute('aria-label', 'Nie możesz zmieniać własnych uprawnień');
      }
      if (schoolManagerCheckbox) {
        schoolManagerCheckbox.disabled = true;
        schoolManagerCheckbox.setAttribute('aria-label', 'Nie możesz zmieniać własnych uprawnień');
      }
      if (teacherCheckbox) {
        teacherCheckbox.disabled = true;
        teacherCheckbox.setAttribute('aria-label', 'Nie możesz zmieniać własnych uprawnień');
      }
      
      // Add visual indicator
      const roleSelectWrapper = document.querySelector('#edit-administration-modal .role-select-wrapper');
      if (roleSelectWrapper) {
        const warningMsg = document.createElement('div');
        warningMsg.className = 'role-warning';
        warningMsg.style.cssText = 'color: var(--state-warning, #f59e0b); font-size: 12px; margin-top: 8px; font-style: italic;';
        warningMsg.textContent = 'Nie możesz zmieniać własnych uprawnień';
        roleSelectWrapper.appendChild(warningMsg);
      }
    } else {
      // Re-enable checkboxes if editing someone else
      if (principalCheckbox) {
        principalCheckbox.disabled = false;
        principalCheckbox.removeAttribute('aria-label');
      }
      if (schoolManagerCheckbox) {
        schoolManagerCheckbox.disabled = false;
        schoolManagerCheckbox.removeAttribute('aria-label');
      }
      if (teacherCheckbox) {
        teacherCheckbox.disabled = false;
        teacherCheckbox.removeAttribute('aria-label');
      }
    }
    
    // Set initial checkbox states from button data (will be overridden by API data)
    if (principalCheckbox) {
      const hasPrincipal = Array.isArray(roles) && roles.includes('principal');
      if (hasPrincipal) {
        principalCheckbox.setAttribute('checked', 'checked');
        principalCheckbox.checked = true;
      } else {
        principalCheckbox.removeAttribute('checked');
        principalCheckbox.checked = false;
      }
    }
    if (schoolManagerCheckbox) {
      const hasSchoolManager = Array.isArray(roles) && roles.includes('school_manager');
      if (hasSchoolManager) {
        schoolManagerCheckbox.setAttribute('checked', 'checked');
        schoolManagerCheckbox.checked = true;
      } else {
        schoolManagerCheckbox.removeAttribute('checked');
        schoolManagerCheckbox.checked = false;
      }
    }
    if (teacherCheckbox) {
      const hasTeacher = Array.isArray(roles) && roles.includes('teacher');
      if (hasTeacher) {
        teacherCheckbox.setAttribute('checked', 'checked');
        teacherCheckbox.checked = true;
      } else {
        teacherCheckbox.removeAttribute('checked');
        teacherCheckbox.checked = false;
      }
    }

    modal.setAttribute('aria-hidden', 'false');
    modal.classList.add('is-open');

    // Fetch full administration data from API
    try {
      const result = await api.get(`${API_BASE}/${administrationId}`);
      
      if (result.success && result.data) {
        // API client wraps response: {success: true, data: responseData}
        // HandleStatusCode wraps: {success: true, data: {data: {id, type, attributes}}}
        // So structure is: result.data = {success: true, data: {data: {...}}}
        // Or: result.data = {data: {id, type, attributes}}
        
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
          
          // Roles come from attributes.roles as an array
          const roles = Array.isArray(attributes.roles) ? attributes.roles : [];
          
          if (principalCheckbox) {
            const hasPrincipal = roles.includes('principal');
            if (hasPrincipal) {
              principalCheckbox.setAttribute('checked', 'checked');
              principalCheckbox.checked = true;
            } else {
              principalCheckbox.removeAttribute('checked');
              principalCheckbox.checked = false;
            }
          }
          
          if (schoolManagerCheckbox) {
            const hasSchoolManager = roles.includes('school_manager');
            if (hasSchoolManager) {
              schoolManagerCheckbox.setAttribute('checked', 'checked');
              schoolManagerCheckbox.checked = true;
            } else {
              schoolManagerCheckbox.removeAttribute('checked');
              schoolManagerCheckbox.checked = false;
            }
          }
          
          if (teacherCheckbox) {
            const hasTeacher = roles.includes('teacher');
            if (hasTeacher) {
              teacherCheckbox.setAttribute('checked', 'checked');
              teacherCheckbox.checked = true;
            } else {
              teacherCheckbox.removeAttribute('checked');
              teacherCheckbox.checked = false;
            }
          }
        }
      }
    } catch (error) {
      console.error('Error fetching administration data:', error);
    }

    const saveBtn = document.getElementById('edit-administration-save-btn');
    if (saveBtn) {
      saveBtn.disabled = false;
      saveBtn.removeAttribute('aria-disabled');
      saveBtn.classList.remove('is-disabled');
    }

    const form = document.getElementById('edit-administration-form');
    if (form) {
      const formInputs = form.querySelectorAll('input, select');
      const enableSaveBtn = () => {
        if (saveBtn) {
          saveBtn.disabled = false;
          saveBtn.removeAttribute('aria-disabled');
          saveBtn.classList.remove('is-disabled');
        }
      };
      
      formInputs.forEach(input => {
        const newInput = input.cloneNode(true);
        input.parentNode.replaceChild(newInput, input);
        newInput.addEventListener('input', enableSaveBtn);
        newInput.addEventListener('change', enableSaveBtn);
      });
    }

    const menu = btn.closest('.headmasters-menu');
    if (menu) menu.open = false;
  }

  setupEditAdministrationHandler();

  // Form submission handlers
  const addForm = document.getElementById('add-administration-form');
  if (addForm) {
    addForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const submitBtn = addForm.querySelector('button[type="submit"]');
      const originalText = submitBtn.textContent;
      submitBtn.disabled = true;
      submitBtn.textContent = 'Adding...';

      try {
        const formData = new FormData(addForm);
        
        const roles = [];
        const principalCheckbox = document.getElementById('add-administration-role-principal');
        const schoolManagerCheckbox = document.getElementById('add-administration-role-school-manager');
        const teacherCheckbox = document.getElementById('add-administration-role-teacher');
        if (principalCheckbox && principalCheckbox.checked) roles.push('principal');
        if (schoolManagerCheckbox && schoolManagerCheckbox.checked) roles.push('school_manager');
        if (teacherCheckbox && teacherCheckbox.checked) roles.push('teacher');
        
        const data = {
          administration: {
            school_id: window.MANAGEMENT_SCHOOL_ID || formData.get('administration[school_id]'),
            first_name: formData.get('administration[first_name]'),
            last_name: formData.get('administration[last_name]'),
            email: formData.get('administration[email]'),
            roles: roles,
            metadata: {
              phone: formData.get('administration[metadata][phone]') || ''
            }
          }
        };

        const result = await api.post(API_BASE, data);
        
        if (result.success) {
          const modal = document.getElementById('add-administration-modal');
          if (modal) {
            const focusedElement = modal.querySelector(':focus');
            if (focusedElement) focusedElement.blur();
            modal.setAttribute('aria-hidden', 'true');
            modal.classList.remove('is-open');
            addForm.reset();
          }
          currentPage = 1;
          hasMore = true;
          allAdministrations = [];
          currentSearchTerm = '';
          searchInput.value = '';
          loadAdministrations(1);
        } else {
          console.error('API error:', result.error);
          alert('Error: ' + String(result.error || 'Failed to create administration'));
          submitBtn.disabled = false;
          submitBtn.textContent = originalText;
        }
      } catch (error) {
        console.error('Form submission error:', error);
        alert('Error: ' + String(error.message || 'Unknown error'));
        submitBtn.disabled = false;
        submitBtn.textContent = originalText;
      }
    });
  }

  const editForm = document.getElementById('edit-administration-form');
  if (editForm) {
    editForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const submitBtn = editForm.querySelector('button[type="submit"]');
      const originalText = submitBtn.textContent;
      const administrationIdField = document.getElementById('edit-administration-id');
      
      if (!administrationIdField || !administrationIdField.value) {
        alert('Error: Administration ID is missing');
        return;
      }
      
      const administrationId = administrationIdField.value;
      
      submitBtn.disabled = true;
      submitBtn.textContent = 'Saving...';

      try {
        const formData = new FormData(editForm);
        
        const roles = [];
        const principalCheckbox = document.getElementById('edit-administration-role-principal');
        const schoolManagerCheckbox = document.getElementById('edit-administration-role-school-manager');
        const teacherCheckbox = document.getElementById('edit-administration-role-teacher');
        if (principalCheckbox && principalCheckbox.checked) roles.push('principal');
        if (schoolManagerCheckbox && schoolManagerCheckbox.checked) roles.push('school_manager');
        if (teacherCheckbox && teacherCheckbox.checked) roles.push('teacher');
        
        const data = {
          administration: {
            school_id: window.MANAGEMENT_SCHOOL_ID || formData.get('administration[school_id]'),
            first_name: formData.get('administration[first_name]'),
            last_name: formData.get('administration[last_name]'),
            email: formData.get('administration[email]'),
            roles: roles,
            metadata: {
              phone: formData.get('administration[metadata][phone]') || ''
            }
          }
        };

        const result = await api.patch(`${API_BASE}/${administrationId}`, data);
        
        if (result.success) {
          const modal = document.getElementById('edit-administration-modal');
          if (modal) {
            const focusedElement = modal.querySelector(':focus');
            if (focusedElement) focusedElement.blur();
            modal.setAttribute('aria-hidden', 'true');
            modal.classList.remove('is-open');
          }
          currentPage = 1;
          hasMore = true;
          allAdministrations = [];
          currentSearchTerm = '';
          searchInput.value = '';
          loadAdministrations(1);
        } else {
          console.error('API error:', result.error);
          // Check if it's a forbidden error (403) - user trying to change own roles
          let errorMessage = result.error || 'Failed to update administration';
          if (result.errors && Array.isArray(result.errors) && result.errors.length > 0) {
            errorMessage = result.errors.join(', ');
          }
          alert('Error: ' + String(errorMessage));
          submitBtn.disabled = false;
          submitBtn.textContent = originalText;
        }
      } catch (error) {
        console.error('Form submission error:', error);
        alert('Error: ' + String(error.message || 'Unknown error'));
        submitBtn.disabled = false;
        submitBtn.textContent = originalText;
      }
    });
  }

  // Resend invite handler
  function setupResendInviteHandler() {
    if (tbody) {
      tbody.removeEventListener('click', handleResendInviteClick, true);
      tbody.addEventListener('click', handleResendInviteClick, true);
    }
  }

  async function handleResendInviteClick(e) {
    const btn = e.target.closest('[data-action="resend-invite"]');
    if (!btn) return;

    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();

    const administrationId = btn.getAttribute('data-administration-id');
    
    if (!administrationId) {
      console.error('Error: Administration ID is missing');
      return;
    }
    
    const originalText = btn.textContent;
    btn.disabled = true;
    btn.textContent = 'Sending...';
    
    try {
      const result = await api.post(`${API_BASE}/${administrationId}/resend_invite`, {});
      
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

  setupResendInviteHandler();

  // Deactivate administration handler
  let deactivateAdministrationId = null;
  
  function setupDeactivateAdministrationHandler() {
    if (tbody) {
      tbody.removeEventListener('click', handleDeactivateAdministrationClick, true);
      tbody.addEventListener('click', handleDeactivateAdministrationClick, true);
    }
  }

  function handleDeactivateAdministrationClick(e) {
    const btn = e.target.closest('[data-action="deactivate-administration"]');
    if (!btn) return;

    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();

    deactivateAdministrationId = btn.getAttribute('data-administration-id');
    const name = btn.getAttribute('data-administration-name') || '';
    const isLocked = btn.getAttribute('data-administration-is-locked') === 'true';
    
    const deactivateNameEl = document.querySelector('[data-deactivate-name]');
    if (deactivateNameEl) {
      deactivateNameEl.textContent = name;
    }
    
    const modalTitle = document.getElementById('deactivate-administration-title');
    const modalMessage = document.getElementById('deactivate-administration-message');
    const confirmBtn = document.getElementById('deactivate-administration-confirm-btn');
    
    if (confirmBtn) {
      confirmBtn.disabled = false;
      confirmBtn.removeAttribute('aria-disabled');
    }
    
    if (isLocked) {
      if (modalTitle) modalTitle.textContent = 'Activate administration';
      if (modalMessage) modalMessage.textContent = `Are you sure you want to activate ${name}? They will regain access immediately.`;
      if (confirmBtn) {
        confirmBtn.textContent = 'Activate';
        confirmBtn.classList.remove('schools-modal__primary--danger');
      }
    } else {
      if (modalTitle) modalTitle.textContent = 'Deactivate administration';
      if (modalMessage) modalMessage.textContent = `Are you sure you want to deactivate ${name}? They will lose access immediately.`;
      if (confirmBtn) {
        confirmBtn.textContent = 'Deactivate';
        confirmBtn.classList.add('schools-modal__primary--danger');
      }
    }
    
    const menu = btn.closest('.headmasters-menu');
    if (menu) menu.open = false;
    
    const deactivateModal = document.getElementById('deactivate-administration-modal');
    if (deactivateModal) {
      deactivateModal.setAttribute('aria-hidden', 'false');
      deactivateModal.classList.add('is-open');
    }
  }

  setupDeactivateAdministrationHandler();

  // Deactivate administration confirm
  const deactivateBtn = document.getElementById('deactivate-administration-confirm-btn');
  if (deactivateBtn) {
    deactivateBtn.addEventListener('click', async () => {
      if (!deactivateAdministrationId) return;
      
      const originalText = deactivateBtn.textContent;
      deactivateBtn.disabled = true;
      deactivateBtn.textContent = 'Processing...';

      try {
        const result = await api.post(`${API_BASE}/${deactivateAdministrationId}/lock`, {});
        
        if (result.success) {
          const modal = document.getElementById('deactivate-administration-modal');
          if (modal) {
            const focusedElement = modal.querySelector(':focus');
            if (focusedElement) focusedElement.blur();
            modal.setAttribute('aria-hidden', 'true');
            modal.classList.remove('is-open');
          }
          
          const triggerBtn = Array.from(document.querySelectorAll('[data-action="deactivate-administration"]'))
            .find(btn => btn.getAttribute('data-administration-id') === deactivateAdministrationId);
          
          if (triggerBtn) {
            const wasLocked = triggerBtn.getAttribute('data-administration-is-locked') === 'true';
            const newLockedStatus = !wasLocked;
            
            const row = triggerBtn.closest('tr');
            if (row) {
              const statusCell = row.querySelector('td:nth-child(5)');
              if (statusCell) {
                const statusBadge = statusCell.querySelector('span');
                if (statusBadge) {
                  if (newLockedStatus) {
                    statusBadge.textContent = 'Inactive';
                    statusBadge.style.color = 'var(--state-error)';
                  } else {
                    statusBadge.textContent = 'Active';
                    statusBadge.style.color = 'var(--state-success)';
                  }
                }
              }
              
              triggerBtn.textContent = newLockedStatus ? 'Activate' : 'Deactivate';
              triggerBtn.setAttribute('data-administration-is-locked', newLockedStatus ? 'true' : 'false');
            }
            
            const administrationIndex = allAdministrations.findIndex(a => {
              const attrs = a.attributes || a;
              const id = a.id || attrs.id;
              return String(id) === String(deactivateAdministrationId);
            });
            
            if (administrationIndex !== -1) {
              const administration = allAdministrations[administrationIndex];
              const attrs = administration.attributes || administration;
              
              if (administration.attributes) {
                administration.attributes.is_locked = newLockedStatus;
                administration.attributes.locked_at = newLockedStatus ? new Date().toISOString() : null;
              } else if (attrs) {
                attrs.is_locked = newLockedStatus;
                attrs.locked_at = newLockedStatus ? new Date().toISOString() : null;
              }
            }
          } else {
            currentPage = 1;
            hasMore = true;
            allAdministrations = [];
            currentSearchTerm = '';
            if (searchInput) searchInput.value = '';
            loadAdministrations(1);
          }
        } else {
          alert('Error: ' + String(result.error || 'Failed to update administration status'));
          deactivateBtn.disabled = false;
          deactivateBtn.textContent = originalText;
        }
      } catch (error) {
        console.error('Deactivate error:', error);
        alert('Error: ' + String(error.message || 'Unknown error'));
        deactivateBtn.disabled = false;
        deactivateBtn.textContent = originalText;
      }
    });
  }

  // Load initial administrations
  loadAdministrations(1);
});

