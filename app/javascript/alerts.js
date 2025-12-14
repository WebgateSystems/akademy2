// Alert dismiss functionality
(function() {
  document.addEventListener('DOMContentLoaded', function() {
    // Handle alert dismiss buttons
    document.querySelectorAll('[data-dismiss-alert]').forEach(function(button) {
      button.addEventListener('click', function() {
        const alert = this.closest('.alert');
        if (alert) {
          alert.style.opacity = '0';
          alert.style.transform = 'translateY(-10px)';
          alert.style.transition = 'opacity 0.2s ease, transform 0.2s ease';
          setTimeout(function() {
            alert.remove();
          }, 200);
        }
      });
    });

    // Auto-dismiss success alerts after 5 seconds
    document.querySelectorAll('.alert-success').forEach(function(alert) {
      setTimeout(function() {
        const closeBtn = alert.querySelector('[data-dismiss-alert]');
        if (closeBtn) {
          closeBtn.click();
        }
      }, 5000);
    });
  });
})();

