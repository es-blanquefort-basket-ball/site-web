// États internes de l’interface : leur correspondance SQL reste à vérifier.
export const stages = Object.freeze(['Avant-match', 'Premier quart-temps', 'Deuxième quart-temps', 'Mi-temps', 'Troisième quart-temps', 'Quatrième quart-temps', 'Match terminé']);
export function canShowScore(match) {
  // Règle explicite par équipe fournie par la base, jamais déduite d’un libellé d’âge.
  return match.scorePolicy === 'numeric' && typeof match.competitionCode === 'string'
    && match.competitionCode !== 'DMU11-10-P2';
}
export function normalizeLive(match) {
  if (!Number.isInteger(match.stage) || match.stage < 0 || match.stage >= stages.length) throw new Error('Étape Live inconnue : raccordement à vérifier.');
  const next = { ...match };
  if (!canShowScore(match)) { next.clubScore = null; next.opponentScore = null; }
  else for (const key of ['clubScore','opponentScore']) {
    if (next[key] == null) next[key] = null;
    else if (!Number.isInteger(next[key]) || next[key] < 0 || next[key] > 2147483647) throw new Error('Score Live reçu invalide : actualiser ou vérifier le raccordement.');
  }
  return next;
}
export function liveChange(match, patch) {
  const keys = Object.keys(patch);
  if (keys.length === 1 && keys[0] === 'stage') {
    if (!Number.isInteger(patch.stage) || patch.stage < 0 || patch.stage >= stages.length) throw new Error('Étape Live invalide.');
    if (patch.stage === match.stage) throw new Error('Aucun changement d’étape.');
    return { stage: patch.stage };
  }
  if (keys.length !== 2 || !keys.includes('clubScore') || !keys.includes('opponentScore')) throw new Error('Modifier séparément l’étape ou le score Live.');
  if (!canShowScore(match)) throw new Error('Score numérique interdit pour cette équipe.');
  const result = {};
  for (const key of keys) {
    const value = patch[key];
    if (value === '' || value === null) result[key] = null;
    else if (/^\d+$/.test(String(value)) && Number.isSafeInteger(Number(value)) && Number(value) <= 2147483647) result[key] = Number(value);
    else throw new Error('Le score doit être un entier positif ou nul, ou rester vide.');
  }
  if (result.clubScore === (match.clubScore ?? null) && result.opponentScore === (match.opponentScore ?? null)) throw new Error('Aucun changement de score.');
  return result;
}
// Contrat de projection pour une future page publique : aucune identité, aucun résultat FFBB.
export function publicLive(match) {
  const safe = normalizeLive(match);
  return { id: safe.id, teamId: safe.teamId, teamLabel: safe.teamLabel, opponent: safe.opponent, stage: safe.stage,
    ...(canShowScore(safe) ? { clubScore: safe.clubScore ?? null, opponentScore: safe.opponentScore ?? null } : {}) };
}
