// Contrôle local du normaliseur et des cartes, sans requête réseau.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function element(tag = 'div') {
  return {
    tag, children: [], textContent: '', hidden: true,
    classList: { add() {}, remove() {}, toggle() {} },
    append(...children) { this.children.push(...children); },
    querySelector() { return element(); },
    addEventListener() {}
  };
}

const source = fs.readFileSync(path.join(__dirname, '..', 'calendrier.js'), 'utf8');
const ending = /  fetchMonthEvents\(\);\s*\}\)\(\);\s*$/;
assert(ending.test(source), 'Point de contrôle du script absent');
const sandbox = {
  document: { getElementById: () => element(), createElement: element, addEventListener() {} },
  URL, Intl, Date
};
vm.runInNewContext(source.replace(ending,
  '  globalThis.audit = { normalizeCalendarEntry, createMatchCard };\n})();'), sandbox);
const { normalizeCalendarEntry, createMatchCard } = sandbox.audit;
const row = {
  team_code: 'ÉQUIPE TEST', opponent_name: 'ADVERSAIRE TEST', home_away: 'home',
  local_date: '2026-11-07', venue_name: 'SALLE TEST', round_label: 'J1'
};

for (const time of [null, undefined, '', ' ', '00:00', '00:00:00', '00:00:00.000000']) {
  const normalized = normalizeCalendarEntry({ ...row, local_time: time });
  assert(normalized, `Rencontre écartée pour ${String(time)}`);
  assert.equal(normalized.localDate, row.local_date);
  assert.equal(normalized.localTime, '');
  const timeElement = createMatchCard(normalized).children[0].children[1].children[1];
  assert.equal(timeElement.tag, 'span');
  assert.equal(timeElement.textContent, 'Horaire à confirmer');
}

for (const [input, output] of [['10:30', '10h30'], ['14:00:00', '14h00'], ['19:00:00', '19h00'], ['00:30:00', '00h30']]) {
  const normalized = normalizeCalendarEntry({ ...row, local_time: input });
  assert.equal(normalized.localTime, input);
  const timeElement = createMatchCard(normalized).children[0].children[1].children[1];
  assert.equal(timeElement.tag, 'time');
  assert.equal(timeElement.textContent, output);
}

assert.equal(normalizeCalendarEntry({ ...row, local_date: '', local_time: null }), null);
assert.equal(normalizeCalendarEntry({ ...row, local_time: 'invalide' }), null);
const withoutUrl = normalizeCalendarEntry({ ...row, local_time: null });
assert.equal(withoutUrl.ffbbMatchUrl, null);
assert.equal(withoutUrl.ffbbTeamUrl, null);
assert.notEqual(
  normalizeCalendarEntry({ ...row, team_code: 'U9 garçons 1' }).teamCode,
  normalizeCalendarEntry({ ...row, team_code: 'U9 garçons 2' }).teamCode
);
console.log('OK : dates conservées, heures inconnues affichées, heures renseignées préservées, équipes distinctes, aucun lien inventé.');
