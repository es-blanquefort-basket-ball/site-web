import assert from 'node:assert/strict';
import { createApi, changesFor, groupMatches, validDate, safeFfbbUrl } from '../../app/gestion-matchs-core.js';

export async function runTests() {
  let count = 0;
  const test = async (name, action) => { await action(); count++; console.log(`OK ${name}`); };
  const match = { id: 'test-match-1', teamId: 'test-team-1', date: '2026-11-07', time: '14:30:00', venue: 'SALLE TEST' };
  const values = { date: match.date, time: match.time, venue: match.venue };
  const calls = [];
  let allowed = true, status = 200, publicVenue = 'AUTRE SALLE TEST', updateRows = [{ stable_id: match.id }];
  const binding = { accessRpc: 'TEST_ONLY_ACCESS', readTable: 'TEST_ONLY_MATCHES', read: { id: 'stable_id', teamId: 'team_id', date: 'effective_date' }, matchId: 'stable_id', publicId: 'match_id', manual: { date: 'TEST_manual_date', time: 'TEST_manual_time', venue: 'TEST_manual_venue' } };
  const transport = async (url, options) => {
    calls.push({ url, ...options });
    let data = null;
    if (url.endsWith('/verify')) data = { access_token: 'TEST_TOKEN' };
    else if (url.endsWith('/user')) data = { id: 'TEST_USER' };
    else if (url.includes('/rpc/')) data = allowed;
    else if (options.method === 'PATCH') data = updateRows;
    else if (url.includes('/public_calendar')) data = [{ local_date: match.date, local_time: match.time, venue_name: publicVenue }];
    else if (url.includes('/TEST_ONLY_MATCHES')) data = [{ stable_id: match.id, team_id: match.teamId, effective_date: match.date }];
    return { ok: status === 200, status, json: async () => data };
  };
  const config = { url: 'https://example.test', key: 'TEST_KEY', binding, writesApproved: false };
  const api = createApi(config, transport);
  await test('sans authentification : aucun accès aux rencontres', async () => { await assert.rejects(api.list(), /connexion nécessaire/); assert.equal(calls.length, 0); });
  await test('code : pas de création automatique de compte', async () => { await api.sendCode('compte@example.test'); assert.equal(JSON.parse(calls.at(-1).body).create_user, false); });
  await api.verifyCode('compte@example.test', '123456');
  await test('compte non autorisé : aucune lecture des matchs', async () => { allowed = false; const n = calls.length; await assert.rejects(api.list(), /non autorisé/); assert.equal(calls.length - n, 2); allowed = true; });
  await test('liste : identifiant stable et relation équipe', async () => { const rows = await api.list(); assert.equal(rows[0].id, match.id); assert.equal(rows[0].teamId, match.teamId); });
  await test('date et heure invalides, salle vide et contrôle refusés', () => {
    assert.equal(validDate('2026-02-30'), false);
    for (const change of [{ date: '2026-02-30' }, { time: '24:00' }, { venue: '' }, { venue: 'x\n' + 'y' }, { venue: 'x'.repeat(201) }]) assert.throws(() => changesFor(match, { ...values, ...change }));
    assert.throws(() => changesFor(match, values), /Aucun changement/);
    assert.deepEqual(changesFor(match, { ...values, venue: 'AUTRE SALLE TEST' }), { venue: 'AUTRE SALLE TEST' });
    assert.deepEqual(changesFor(match, { ...values, time: '14:30', venue: 'AUTRE SALLE TEST' }), { venue: 'AUTRE SALLE TEST' });
  });
  await test('informations manquantes inchangées conservées', () => { assert.deepEqual(changesFor({ ...match, time: null, venue: null }, { ...values, time: '', venue: '', date: '2026-11-08' }), { date: '2026-11-08' }); });
  await test('week-ends et séparation stricte des identifiants U11/U9', () => {
    const rows = [match, { ...match, id: '2', teamId: 'test-team-2', date: '2026-11-08' }, { ...match, id: '3', teamId: 'test-u9', date: null }];
    assert.equal(groupMatches(rows).get('2026-11-07').length, 2);
    assert.equal(groupMatches(rows, match.teamId).get('2026-11-07').length, 1);
    assert.equal(groupMatches(rows).get('').length, 1);
  });
  await test('liens FFBB sûrs, aucune URL fabriquée', () => { assert.equal(safeFfbbUrl('javascript:alert(1)'), null); assert.equal(safeFfbbUrl('https://example.test'), null); });
  await test('verrou production : zéro appel réseau à la sauvegarde', async () => { const n = calls.length; await assert.rejects(api.save(match, { ...values, venue: publicVenue }), /désactivé/); assert.equal(calls.length, n); });
  // Suite sur transport factice uniquement : aucun appel Supabase.
  config.writesApproved = true;
  await test('PATCH : uniquement correction manuelle, match identifié', async () => {
    await api.save(match, { ...values, venue: publicVenue });
    const patch = calls.find(call => call.method === 'PATCH');
    assert.deepEqual(JSON.parse(patch.body), { TEST_manual_venue: publicVenue });
    assert.equal(new URL(patch.url).searchParams.get('stable_id'), `eq.${match.id}`);
  });
  await test('zéro ligne autorisée : échec explicite', async () => { updateRows = []; await assert.rejects(api.save(match, { ...values, venue: publicVenue }), /non confirmé/); updateRows = [{ stable_id: match.id }]; });
  await test('propagation publique manquante : aucun faux succès', async () => { publicVenue = 'ANCIENNE SALLE TEST'; await assert.rejects(api.save(match, { ...values, venue: 'AUTRE SALLE TEST' }), /propagation publique non confirmée/); });
  await test('refus REST 403 propagé', async () => { status = 403; await assert.rejects(api.list(), /Accès refusé/); status = 200; });
  await test('schéma inconnu : refus fermé', async () => { config.binding = null; await assert.rejects(api.list(), /en attente de vérification/); });
  await test('déconnexion : jeton supprimé', async () => { await api.logout(); await assert.rejects(api.list(), /connexion nécessaire/); });
  return `${count} contrôles locaux réussis (transport factice, aucune écriture Supabase).`;
}

console.log(await runTests());
