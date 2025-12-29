// Landing page theme handling - runs immediately (not deferred)
(function() {
  const STORAGE_KEY = 'theme';

  function getStoredTheme() {
    return localStorage.getItem(STORAGE_KEY);
  }

  function getSystemTheme() {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function applyTheme(theme) {
    const isDark = theme === 'dark';
    document.documentElement.classList.toggle('theme-dark', isDark);
    document.documentElement.setAttribute('data-theme', theme);
    updateVideoPoster(theme);
  }

  function updateVideoPoster(theme) {
    const video = document.getElementById('hero-intro-video');
    if (!video) return;

    const posterLight = video.dataset.posterLight;
    const posterDark = video.dataset.posterDark;
    const newPoster = theme === 'dark' ? posterDark : posterLight;

    if (newPoster && video.poster !== newPoster) {
      video.poster = newPoster;
    }
  }

  // Apply theme immediately on script load
  const storedTheme = getStoredTheme();
  const effectiveTheme = storedTheme || getSystemTheme();
  applyTheme(effectiveTheme);

  // Setup toggle, year, and poster after DOM is ready
  document.addEventListener('DOMContentLoaded', function() {
    // Update video poster (in case video wasn't in DOM during initial applyTheme)
    updateVideoPoster(effectiveTheme);

    const toggle = document.getElementById('themeToggle');
    const yearEl = document.getElementById('currentYear');
    
    // Set current year
    if (yearEl) {
      yearEl.textContent = new Date().getFullYear();
    }

    // Theme toggle - single icon button (sun in dark mode, moon in light mode)
    if (toggle) {
      toggle.addEventListener('click', function() {
        const currentTheme = document.documentElement.classList.contains('theme-dark') ? 'dark' : 'light';
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        
        localStorage.setItem(STORAGE_KEY, newTheme);
        applyTheme(newTheme);
      });
    }

    // Webinar registration form
    setupWebinarForm();
  });

  function setupWebinarForm() {
    const form = document.getElementById('webinar-registration-form');
    const submitBtn = document.getElementById('webinar-submit-btn');
    const messageEl = document.getElementById('webinar-form-message');
    
    if (!form || !submitBtn) return;

    const requiredFields = form.querySelectorAll('input[required]');
    
    // Enable/disable submit button based on required fields
    function checkFormValidity() {
      let allFilled = true;
      requiredFields.forEach(function(field) {
        if (!field.value.trim()) {
          allFilled = false;
        }
      });
      submitBtn.disabled = !allFilled;
    }

    requiredFields.forEach(function(field) {
      field.addEventListener('input', checkFormValidity);
    });

    // Form submission
    form.addEventListener('submit', async function(e) {
      e.preventDefault();
      
      submitBtn.disabled = true;
      submitBtn.textContent = 'Wysyłanie...';
      messageEl.style.display = 'none';
      messageEl.className = 'webinar-form__message';

      const formData = {
        webinar_registration: {
          first_name: form.querySelector('[name="first_name"]').value.trim(),
          last_name: form.querySelector('[name="last_name"]').value.trim(),
          email: form.querySelector('[name="email"]').value.trim(),
          position: form.querySelector('[name="position"]').value.trim(),
          school_name: form.querySelector('[name="school_name"]').value.trim(),
          phone: form.querySelector('[name="phone"]').value.trim()
        }
      };

      try {
        const response = await fetch('/webinar_registrations', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: JSON.stringify(formData)
        });

        const result = await response.json();

        if (result.success) {
          messageEl.className = 'webinar-form__message webinar-form__message--success';
          messageEl.querySelector('p').textContent = result.message;
          messageEl.style.display = 'block';
          form.reset();
          submitBtn.textContent = '✅ Zapisano!';
          // Keep button disabled after success
        } else {
          messageEl.className = 'webinar-form__message webinar-form__message--error';
          messageEl.querySelector('p').textContent = result.errors ? result.errors.join(', ') : 'Wystąpił błąd. Spróbuj ponownie.';
          messageEl.style.display = 'block';
          submitBtn.disabled = false;
          submitBtn.textContent = 'Zapisz się i odbierz link + prezentację';
        }
      } catch (error) {
        messageEl.className = 'webinar-form__message webinar-form__message--error';
        messageEl.querySelector('p').textContent = 'Wystąpił błąd połączenia. Sprawdź internet i spróbuj ponownie.';
        messageEl.style.display = 'block';
        submitBtn.disabled = false;
        submitBtn.textContent = 'Zapisz się i odbierz link + prezentację';
      }
    });
  }
})();
