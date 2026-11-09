// Préparation hors ligne : aucune connexion à Sheets ou Supabase, aucune écriture.
import { createHash } from 'node:crypto';

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const fields = ['date', 'time', 'venue'];
const clean = value => typeof value === 'string' && value.trim() === '' ? null : (value ?? null);

export function validateBindings(bindings) {
  const ids = new Set();
  const cells = new Set();
  for (const binding of bindings) {
    if (!uuid.test(binding.matchId) || !Number.isInteger(binding.sheetId) ||
        !Number.isInteger(binding.row) || binding.row < 2) throw new Error('Liaison incomplète ou identifiant non UUID');
    const cell = `${binding.sheetId}:${binding.row}`;
    if (ids.has(binding.matchId) || cells.has(cell)) throw new Error('Liaison de rencontre dupliquée');
    ids.add(binding.matchId); cells.add(cell);
  }
  return true;
}

export function scheduleFingerprint(value) {
  return createHash('sha256').update(JSON.stringify(fields.map(field => clean(value[field])))).digest('hex');
}

export function weekendKey(date) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error('Date ISO requise');
  const day = new Date(`${date}T12:00:00Z`);
  if (Number.isNaN(day.getTime()) || day.toISOString().slice(0, 10) !== date) throw new Error('Date invalide');
  day.setUTCDate(day.getUTCDate() - ((day.getUTCDay() + 2) % 7));
  return day.toISOString().slice(0, 10); // vendredi du week-end
}

// base = dernier état partagé ; site = lecture Supabase ; sheet = E:G du classeur.
// Le numéro FBI, la position de ligne, les notes et les affectations ne servent jamais de clé.
export function planSchedule({ binding, base, site, sheet, siteRevision, expectedSheetFingerprint, fbiSourceChanged = false }) {
  validateBindings([binding]);
  if (!Number.isInteger(siteRevision) || siteRevision < 0) throw new Error('Révision Gestion requise');
  if (expectedSheetFingerprint !== scheduleFingerprint(base)) throw new Error('Empreinte de base incohérente');
  const toSite = {}, toSheet = {}, conflicts = [];
  for (const field of fields) {
    const before = clean(base[field]);
    const currentSite = clean(site[field]);
    const currentSheet = clean(sheet[field]);
    const siteChanged = currentSite !== before;
    const sheetChanged = currentSheet !== before;
    if ((siteChanged && currentSite === null) || (sheetChanged && currentSheet === null)) conflicts.push(field);
    else if (siteChanged && sheetChanged && currentSite !== currentSheet) conflicts.push(field);
    else if (sheetChanged && !siteChanged) toSite[field] = currentSheet;
    else if (siteChanged && !sheetChanged) toSheet[field] = currentSite;
  }
  const targetDate = conflicts.includes('date') ? null : (toSite.date ?? toSheet.date ?? site.date);
  const movedWeekend = targetDate && base.date ? weekendKey(targetDate) !== weekendKey(base.date) : false;
  return {
    matchId: binding.matchId, sheetId: binding.sheetId, row: binding.row,
    siteRevision, expectedSheetFingerprint: scheduleFingerprint(sheet),
    toSite, toSheet, conflicts, movedWeekend,
    reviewAssignments: Boolean(movedWeekend), reviewFbiImport: Boolean(fbiSourceChanged),
    blocked: conflicts.length > 0 || Boolean(fbiSourceChanged),
  };
}
