const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const code = fs.readFileSync('site-update.js', 'utf8');
function label(source) {
  const chip = { textContent: 'Prévisualisation — livraison non publiée' };
  vm.runInNewContext(source, { document: { addEventListener: (_, callback) => callback(), querySelectorAll: () => [chip] }, Intl, Date });
  return chip.textContent;
}
assert.equal(label(code), 'Prévisualisation — livraison non publiée');
assert.equal(label(code.replace('SITE_RELEASE_DATE = null', "SITE_RELEASE_DATE = '2026-11-05'")), 'Site mis à jour le 5 novembre 2026');
assert.equal(label(code.replace('SITE_RELEASE_DATE = null', "SITE_RELEASE_DATE = '2026-11-12'")), 'Site mis à jour le 12 novembre 2026');
console.log('Date centralisée : prévisualisation, livraison du 5 novembre et livraison ultérieure vérifiées.');
