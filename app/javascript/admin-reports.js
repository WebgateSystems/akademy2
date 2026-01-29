(function () {
  'use strict';

  const loadedClasses = new Set();

  const renderCertificates = (container, students) => {
    if (!students || students.length === 0) {
      container.innerHTML = '<p class="text-muted" style="margin: 0;">Brak certyfikatów do wyświetlenia</p>';
      return;
    }

    const html = students.map((sc) => {
      const certsHtml = sc.certificates.map((cert) => {
        if (cert.pdf_url) {
          return `<a href="${cert.pdf_url}" target="_blank" rel="noopener" class="certificate-badge" title="Otwórz certyfikat" style="display: inline-flex; align-items: center; gap: 4px; padding: 4px 10px; background: #166534; color: #fff; border-radius: 4px; font-size: 13px; text-decoration: none;">
            <span>${cert.module_title || 'Certyfikat'}</span>
            <i class="bi bi-eye" aria-hidden="true"></i>
          </a>`;
        }
        return `<span class="certificate-badge" style="display: inline-flex; align-items: center; gap: 4px; padding: 4px 10px; background: #94a3b8; color: #fff; border-radius: 4px; font-size: 13px;">
          ${cert.module_title || 'Certyfikat'}
        </span>`;
      }).join('');

      return `<div class="student-cert-row" style="margin-bottom: 12px; padding-bottom: 12px; border-bottom: 1px solid var(--border-primary, #e2e8f0);">
        <div class="student-name" style="font-weight: 600; margin-bottom: 8px;">${sc.student_name}</div>
        <div class="certificates-list" style="display: flex; flex-wrap: wrap; gap: 8px;">${certsHtml}</div>
      </div>`;
    }).join('');

    container.innerHTML = html;
  };

  const fetchCertificates = async (detailsRow) => {
    const url = detailsRow.dataset.certificatesUrl;
    const container = detailsRow.querySelector('.js-certificates-content');
    const loading = detailsRow.querySelector('.js-certificates-loading');

    if (!url || !container) return;

    loading.style.display = 'block';
    container.innerHTML = '';

    try {
      const response = await fetch(url, {
        headers: { 'Accept': 'application/json' }
      });
      const data = await response.json();
      renderCertificates(container, data.students);
    } catch (error) {
      container.innerHTML = '<p class="text-danger" style="margin: 0;">Błąd ładowania danych</p>';
      console.error('Error fetching certificates:', error);
    } finally {
      loading.style.display = 'none';
    }
  };

  const initExpandableRows = () => {
    const expandableRows = document.querySelectorAll('.class-row--expandable');

    expandableRows.forEach((row) => {
      const classId = row.dataset.classId;
      const detailsRow = document.querySelector(`.class-row__details[data-class-id="${classId}"]`);
      const chevron = row.querySelector('.class-row__chevron');

      if (!detailsRow) return;

      const toggleExpand = async () => {
        const isExpanded = row.getAttribute('aria-expanded') === 'true';

        if (isExpanded) {
          row.setAttribute('aria-expanded', 'false');
          row.classList.remove('class-row--expanded');
          detailsRow.style.display = 'none';
          if (chevron) chevron.classList.remove('class-row__chevron--rotated');
        } else {
          row.setAttribute('aria-expanded', 'true');
          row.classList.add('class-row--expanded');
          detailsRow.style.display = 'table-row';
          if (chevron) chevron.classList.add('class-row__chevron--rotated');

          // Fetch certificates only on first expand
          if (!loadedClasses.has(classId)) {
            loadedClasses.add(classId);
            await fetchCertificates(detailsRow);
          }
        }
      };

      row.addEventListener('click', toggleExpand);
      row.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          toggleExpand();
        }
      });
    });
  };

  // Initialize on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initExpandableRows);
  } else {
    initExpandableRows();
  }
})();
