document.addEventListener('DOMContentLoaded', () => {
  // À renseigner avec la date réelle lors de la livraison validée (AAAA-MM-JJ).
  // null empêche d'annoncer une publication qui n'a pas eu lieu.
  const SITE_RELEASE_DATE = null;
  const releaseDate = SITE_RELEASE_DATE && /^\d{4}-\d{2}-\d{2}$/.test(SITE_RELEASE_DATE)
    ? new Date(`${SITE_RELEASE_DATE}T12:00:00`) : null;
  if (releaseDate && !Number.isNaN(releaseDate.getTime())) {
    const label = new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' }).format(releaseDate);
    document.querySelectorAll('[data-site-update]').forEach(chip => {
      chip.textContent = `Site mis à jour le ${label}`;
    });
  }

});
