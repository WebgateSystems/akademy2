document.addEventListener('DOMContentLoaded', () => {
  const likeButtons = document.querySelectorAll('.school-video-card__likes');

  likeButtons.forEach(button => {
    button.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      
      const icon = button.querySelector('img');
      const countSpan = button.querySelector('span');
      let count = parseInt(countSpan.textContent);

      if (icon.src.includes('no-like.svg')) {
        icon.src = '/assets/icons/social/S/like.svg';
        button.classList.add('is-liked');
        button.setAttribute('aria-label', 'Unlike video');
        count++;
      } else {
        icon.src = '/assets/icons/social/S/no-like.svg';
        button.classList.remove('is-liked');
        button.setAttribute('aria-label', 'Like video');
        count--;
      }

      countSpan.textContent = count;
    });
  });
});
