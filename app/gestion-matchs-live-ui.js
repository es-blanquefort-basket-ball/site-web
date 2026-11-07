import { stages, canShowScore } from './gestion-matchs-live.js';
import { groupMatches, missing } from './gestion-matchs-core.js';

export function mountLive(api, config, run) {
  const $ = id => document.getElementById(id);
  let rows = [], selected = null, dirty = false;
  const note = text => { $('live-detail-status').textContent = text; };
  const element = (tag, text) => { const item = document.createElement(tag); item.textContent = text; return item; };
  function sync() {
    $('live-prev').disabled = !selected || selected.stage === 0;
    $('live-next').disabled = !selected || selected.stage === stages.length - 1;
  }
  function close() {
    selected = null; dirty = false; $('live-detail').hidden = true;
    $('live-club-score').value = ''; $('live-opponent-score').value = ''; note(''); sync();
  }
  function display() {
    $('live-detail').hidden = false;
    $('live-match-label').textContent = `${missing(selected.teamLabel)} — ${missing(selected.opponent)}`;
    $('live-reference').textContent = `Référence ${selected.id}`;
    $('live-current').textContent = `Étape actuelle : ${stages[selected.stage]}`;
    $('live-stages').replaceChildren(...stages.map((stage, index) => {
      const item = element('li', stage); if (index === selected.stage) item.setAttribute('aria-current','step'); return item;
    }));
    $('live-score-form').hidden = !canShowScore(selected); $('live-no-score').hidden = canShowScore(selected);
    $('live-club-score').value = selected.clubScore ?? ''; $('live-opponent-score').value = selected.opponentScore ?? '';
    dirty = false; sync();
  }
  function render() {
    $('live-matches').replaceChildren();
    for (const [week,matches] of groupMatches(rows, $('live-team').value)) {
      const section = element('section',''); section.className = 'manager-week';
      section.append(element('h3',week ? `Week-end du ${week}` : 'Date à compléter'));
      for (const match of matches) {
        const button = element('button', `${missing(match.teamLabel)} — ${missing(match.opponent)} · ${stages[match.stage]}`);
        button.type = 'button'; button.className = 'btn live-match-button';
        button.addEventListener('click', () => {
          if (dirty && !window.confirm('Abandonner le score Live non enregistré ?')) return;
          selected = match; display(); note(''); $('live-current').scrollIntoView({block:'nearest'});
        });
        section.append(button);
      }
      $('live-matches').append(section);
    }
    if (!$('live-matches').children.length) $('live-matches').append(element('p','Aucune rencontre disponible pour cette équipe.'));
  }
  async function load() {
    $('live-status').textContent = 'Chargement du Live…';
    try {
      const next = await api.liveList();
      rows = next; const previous = $('live-team').value;
      const teams = new Map(rows.map(row => [row.teamId,row.teamLabel]));
      $('live-team').replaceChildren(new Option('Toutes les équipes autorisées',''));
      for (const [id,label] of teams) $('live-team').append(new Option(missing(label),id));
      $('live-team').value = teams.has(previous) ? previous : '';
      close(); render(); $('live-status').textContent = `${rows.length} rencontre(s) Live accessible(s).`;
    } catch (error) { reset(); $('live-status').textContent = error.message; throw error; }
  }
  async function save(patch) {
    note('Chargement : modification non enregistrée…');
    try {
      const saved = await api.saveLive(selected, patch);
      const inputs = [$('live-club-score').value,$('live-opponent-score').value], wasDirty = dirty;
      const scoreChange = Object.hasOwn(patch,'clubScore');
      rows = rows.map(row => row.id === saved.id ? saved : row); selected = saved; display(); render();
      if (!scoreChange && wasDirty) { $('live-club-score').value = inputs[0]; $('live-opponent-score').value = inputs[1]; dirty = true; }
      note(`${config.simulation ? 'Simulation locale enregistrée' : 'Enregistrement Live confirmé après relecture'}${dirty ? ' — score saisi toujours non enregistré.' : '.'}`);
    } catch (error) { note(error.message); }
  }
  $('live-prev').addEventListener('click', () => run(() => save({stage:selected.stage-1})));
  $('live-next').addEventListener('click', () => run(() => save({stage:selected.stage+1})));
  $('live-score-form').addEventListener('input', () => { dirty = true; note('Score modifié, non enregistré.'); });
  $('live-score-form').addEventListener('submit', event => { event.preventDefault(); run(() => save({clubScore:$('live-club-score').value,opponentScore:$('live-opponent-score').value})); });
  $('live-team').addEventListener('change', () => {
    if (dirty && !window.confirm('Abandonner le score Live non enregistré ?')) { $('live-team').value = selected?.teamId || ''; return; }
    close(); render();
  });
  $('live-reload').addEventListener('click', () => { if (!dirty || window.confirm('Abandonner le score Live non enregistré et actualiser ?')) run(load); });
  $('live-close').addEventListener('click', () => { if (!dirty || window.confirm('Abandonner le score Live non enregistré ?')) close(); });
  window.addEventListener('beforeunload', event => { if (dirty) { event.preventDefault(); event.returnValue = ''; } });
  function reset() { rows = []; close(); $('live-matches').replaceChildren(); $('live-team').replaceChildren(new Option('Toutes les équipes autorisées','')); }
  const confirmLeave = () => !dirty || window.confirm('Abandonner le score Live non enregistré ?');
  return { load, reset, sync, confirmLeave };
}
