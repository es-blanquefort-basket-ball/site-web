
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

  // Accueil uniquement : dates publiques, sans jeton GitHub ni donnée personnelle affichée.
  const updatedBadge = document.getElementById('site-last-updated');
  if (updatedBadge) {
    const parseUpdateDate = value => {
      if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T.*(?:Z|[+-]\d{2}:\d{2})$/.test(value)) return null;
      const timestamp = Date.parse(value);
      return Number.isFinite(timestamp) ? timestamp : null;
    };
    const readPublicDate = async (url, headers, extract) => {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 8000);
      try {
        const response = await fetch(url, { headers, signal: controller.signal, cache: 'no-store', credentials: 'omit' });
        if (!response.ok) throw new Error('Date indisponible');
        return parseUpdateDate(extract(await response.json()));
      } finally {
        clearTimeout(timeout);
      }
    };
    const loadLastUpdate = async () => {
      // Aucun filtre de chemin : tous les fichiers enregistrés sur main sont concernés.
      const dates = await Promise.allSettled([
        readPublicDate(
          'https://api.github.com/repos/es-blanquefort-basket-ball/site-web/commits?sha=main&per_page=1',
          { Accept: 'application/vnd.github+json' },
          rows => rows[0]?.commit?.committer?.date
        ),
        // Vue publique existante ; pas de filtre de mois ni d’équipe.
        readPublicDate(
          'https://fgswygeqstgagmipltpq.supabase.co/rest/v1/public_calendar?select=updated_at&updated_at=not.is.null&order=updated_at.desc&limit=1',
          { apikey: 'sb_publishable_dsoHXhS222GToiMUIpGkCA_lFPAJm-A', Accept: 'application/json' },
          rows => rows[0]?.updated_at
        )
      ]);
      const available = dates.filter(result => result.status === 'fulfilled' && result.value !== null)
        .map(result => result.value);
      if (!available.length) return;
      const date = new Intl.DateTimeFormat('fr-FR', {
        day: 'numeric', month: 'long', year: 'numeric', timeZone: 'Europe/Paris'
      }).format(new Date(Math.max(...available)));
      updatedBadge.querySelector('.badge').textContent = `Dernière mise à jour le ${date}`;
      updatedBadge.hidden = false;
    };
    loadLastUpdate();
  }

});
