import assert from 'node:assert/strict';
import { planSchedule, scheduleFingerprint, validateBindings, weekendKey } from './sheets-sync-core.mjs';

const binding = { matchId: '00000000-0000-4000-8000-000000000201', sheetId: 484447378, row: 2 };
const base = { date: '2026-11-07', time: '13:00', venue: 'SALLE TEST' };
const input = { binding, base, site: { ...base }, sheet: { ...base }, siteRevision: 3,
  expectedSheetFingerprint: scheduleFingerprint(base) };
const plan = changes => planSchedule({ ...input, ...changes });
assert.equal(validateBindings([binding]), true);
assert.throws(() => validateBindings([binding, { ...binding, matchId: '00000000-0000-4000-8000-000000000202' }]), /dupliquée/);
assert.throws(() => validateBindings([{ ...binding, matchId: '6' }]), /UUID/);
assert.deepEqual(plan({ sheet: { ...base, time: '14:00' } }).toSite, { time: '14:00' });
assert.deepEqual(plan({ site: { ...base, venue: 'AUTRE SALLE TEST' } }).toSheet, { venue: 'AUTRE SALLE TEST' });
assert.deepEqual(plan({ site: { ...base, time: '14:00' }, sheet: { ...base, time: '15:00' } }).conflicts, ['time']);
assert.deepEqual(plan({ sheet: { ...base, time: '' } }).conflicts, ['time']);
assert.deepEqual(plan({ sheet: { ...base, time: null } }).conflicts, ['time']);
assert.equal(plan({ site: { ...base, date: '2026-11-14' } }).reviewAssignments, true);
assert.equal(weekendKey('2026-11-07'), weekendKey('2026-11-08'));
assert.equal(plan({ fbiSourceChanged: true }).blocked, true);
assert.throws(() => plan({ expectedSheetFingerprint: 'stale' }), /incohérente/);
console.log('12 contrôles de planification Sheets/Supabase hors ligne réussis.');
