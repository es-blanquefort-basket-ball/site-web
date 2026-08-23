
document.addEventListener('DOMContentLoaded', () => {
  const header = document.getElementById('hdr');
  const burger = document.querySelector('.burger');
  const nav = document.querySelector('.navlinks');

  if (burger && nav) {
    burger.setAttribute('type', 'button');
    burger.setAttribute('aria-expanded', 'false');

    const closeMenu = () => {
      nav.classList.remove('open');
      if (header) header.classList.remove('open');
      burger.setAttribute('aria-expanded', 'false');
    };

    const toggleMenu = (event) => {
      event.preventDefault();
      event.stopPropagation();

      const isOpen = nav.classList.toggle('open');
      if (header) header.classList.toggle('open', isOpen);
      burger.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    };

    burger.addEventListener('click', toggleMenu);

    nav.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', closeMenu);
    });

    document.addEventListener('click', event => {
      if (!nav.contains(event.target) && !burger.contains(event.target)) {
        closeMenu();
      }
    });

    document.addEventListener('keydown', event => {
      if (event.key === 'Escape') closeMenu();
    });

    window.addEventListener('resize', () => {
      if (window.innerWidth > 1024) closeMenu();
    });
  }

  // Animations existantes
  const els = document.querySelectorAll('.reveal,.card,.stat');
  if ('IntersectionObserver' in window && els.length) {
    const io = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (e.isIntersecting) e.target.classList.add('in');
      });
    }, { threshold: .12 });
    els.forEach(el => io.observe(el));
  }

  // Compteurs existants
  const counters = document.querySelectorAll('[data-count]');
  if (counters.length) {
    const animate = (el) => {
      if (el.dataset.done) return;
      el.dataset.done = '1';
      const target = parseInt(el.dataset.count, 10) || 0;
      const suffix = el.dataset.suffix || '';
      const duration = 1100;
      const start = performance.now();

      const step = (now) => {
        const progress = Math.min((now - start) / duration, 1);
        const eased = 1 - Math.pow(1 - progress, 3);
        el.textContent = Math.round(target * eased) + suffix;
        if (progress < 1) requestAnimationFrame(step);
      };
      requestAnimationFrame(step);
    };

    if ('IntersectionObserver' in window) {
      const counterObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) animate(entry.target);
        });
      }, { threshold: .35 });
      counters.forEach(el => counterObserver.observe(el));
    } else {
      counters.forEach(animate);
    }
  }
});
