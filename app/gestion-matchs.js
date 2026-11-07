import { config } from './gestion-matchs-config.js';
import { createApi, groupMatches, changesFor, missing, safeFfbbUrl } from './gestion-matchs-core.js';

const api = createApi(config);
const $ = id => document.getElementById(id);
let rows = [], selected = null, pending = null, email = '', busy = false;
const labels = { date: 'Date', time: 'Horaire', venue: 'Salle' };
const values = () => Object.fromEntries(Object.keys(labels).map(key => [key, $(key).value]));
function message(text, edit = false) { $(edit ? 'edit-status' : 'status').textContent = text; }
function clearPrivate() {
  rows = []; selected = null; pending = null;
  $('matches').replaceChildren(); $('team').replaceChildren(new Option('Toutes les équipes', ''));
  $('workspace').hidden = true; $('login').hidden = false;
  $('editor').close(); $('edit-form').reset(); $('match-label').textContent = '';
  $('changes').replaceChildren(); $('code').value = '';
  $('code-form').hidden = true;
}
async function run(action, edit = false) {
  if (busy) return;
  busy = true;
  document.querySelectorAll('button').forEach(button => { button.disabled = true; });
  message('Chargement…', edit);
  try { await action(); } catch (error) { message(error.message, edit); }
  finally {
    busy = false;
    document.querySelectorAll('button').forEach(button => { button.disabled = false; });
  }
}
function node(tag, text, className) {
  const element = document.createElement(tag); element.textContent = text;
  if (className) element.className = className;
  return element;
}
function render() {
  const root = $('matches'); root.replaceChildren();
  const groups = groupMatches(rows, $('team').value);
  if (!groups.size) root.append(node('p', 'Aucune rencontre disponible.'));
  for (const [week, matches] of groups) {
    const section = node('section', '', 'manager-week');
    const date = week ? new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' }).format(new Date(`${week}T12:00:00Z`)) : null;
    section.append(node('h3', date ? `Week-end du ${date}` : 'Date à compléter'));
    for (const match of matches) {
      const card = node('article', '', 'card');
      card.append(node('h4', `${missing(match.teamLabel)} — ${missing(match.opponent)}`));
      card.append(node('p', `${missing(match.date)} · ${missing(match.time)} · ${missing(match.venue)}`));
      card.append(node('p', match.homeAway === 'home' ? 'Domicile' : match.homeAway === 'away' ? 'Extérieur' : 'Domicile / extérieur : [À COMPLÉTER]'));
      for (const [field, title] of [['ffbbMatchUrl','Rencontre FFBB'],['ffbbTeamUrl','Équipe FFBB']]) {
        const url = safeFfbbUrl(match[field]);
        if (url) { const link = node('a', title, 'pill'); link.href = url; link.target = '_blank'; link.rel = 'noopener noreferrer'; card.append(link); }
      }
      const button = node('button', 'Modifier', 'btn btn-primary'); button.type = 'button';
      button.setAttribute('aria-label', `Modifier ${missing(match.teamLabel)} contre ${missing(match.opponent)}`);
      button.addEventListener('click', () => {
        selected = match; pending = null;
        $('match-label').textContent = `${missing(match.teamLabel)} — ${missing(match.opponent)} · Référence ${match.id}`;
        for (const key of Object.keys(labels)) $(key).value = match[key] || '';
        resetReview(); message('', true); $('editor').showModal();
      });
      card.append(button); section.append(card);
    }
    root.append(section);
  }
}
async function load() {
  const next = await api.list();
  const previousTeam = $('team').value;
  rows = next;
  const teams = new Map(rows.map(row => [row.teamId, row.teamLabel]));
  $('team').replaceChildren(new Option('Toutes les équipes', ''));
  for (const [id, label] of teams) $('team').append(new Option(missing(label), id));
  $('team').value = teams.has(previousTeam) ? previousTeam : '';
  $('login').hidden = true; $('workspace').hidden = false;
  render(); message(`${rows.length} rencontre(s) chargée(s).`);
}
function resetReview() {
  pending = null; $('review').hidden = true; $('save').hidden = true;
  $('prepare').hidden = false; $('confirmation').checked = false;
}
$('email-form').addEventListener('submit', event => {
  event.preventDefault();
  run(async () => {
    email = $('email').value.trim(); await api.sendCode(email);
    $('code-form').hidden = false; $('code').value = ''; $('code').focus();
    message('Si cette adresse peut se connecter, un code lui a été envoyé.');
  });
});
$('email').addEventListener('input', () => { $('code-form').hidden = true; $('code').value = ''; });
$('code-form').addEventListener('submit', event => {
  event.preventDefault();
  run(async () => {
    await api.verifyCode(email, $('code').value.trim()); $('code').value = '';
    try { await load(); }
    catch (error) { clearPrivate(); await api.logout().catch(() => {}); throw error; }
  });
});
$('logout').addEventListener('click', () => run(async () => { clearPrivate(); await api.logout(); message('Déconnexion effectuée.'); }));
$('reload').addEventListener('click', () => run(async () => {
  try { await load(); } catch (error) { clearPrivate(); await api.logout().catch(() => {}); throw error; }
}));
$('team').addEventListener('change', render);
$('edit-form').addEventListener('input', event => { if (event.target.id !== 'confirmation') resetReview(); });
$('edit-form').addEventListener('submit', event => {
  event.preventDefault();
  run(async () => {
    const changes = changesFor(selected, values());
    await api.authorize();
    pending = { ...values() }; $('changes').replaceChildren();
    for (const [key, value] of Object.entries(changes)) $('changes').append(node('li', `${labels[key]} : ${missing(selected[key])} → ${value}`));
    $('review').hidden = false; $('save').hidden = false; $('prepare').hidden = true;
    message(config.writesApproved ? 'Relire puis confirmer les modifications.' : 'Enregistrement désactivé dans cette version : vérifications Supabase et validation humaine en attente.', true);
  }, true);
});
$('save').addEventListener('click', () => run(async () => {
  if (!pending || !$('confirmation').checked) throw new Error('Confirmer explicitement les changements avant enregistrement.');
  await api.save(selected, pending);
  // Relecture privée après vérification de la vue publique, sans mise à jour optimiste.
  await load(); $('editor').close(); selected = null; pending = null;
  message('Correction enregistrée, rencontre rechargée et calendrier public vérifié.');
}, true));
$('cancel').addEventListener('click', () => { $('editor').close(); resetReview(); selected = null; });
$('editor').addEventListener('cancel', event => { if (busy) event.preventDefault(); else { resetReview(); selected = null; } });
message('Connexion requise. Les corrections sont désactivées jusqu’à validation des droits Supabase.');
