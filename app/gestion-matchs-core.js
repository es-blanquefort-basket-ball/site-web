import { normalizeLive, liveChange } from './gestion-matchs-live.js';
// Logique indépendante du DOM, également utilisée par les tests locaux.
export const missing = value => value == null || value === '' ? '[À COMPLÉTER]' : String(value);
export function validDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(`${value}T12:00:00Z`);
  return !Number.isNaN(+date) && date.toISOString().slice(0, 10) === value && value >= '1900-01-01' && value <= '2100-12-31';
}
export function weekKey(value) {
  if (!validDate(value)) return '';
  const date = new Date(`${value}T12:00:00Z`);
  date.setUTCDate(date.getUTCDate() + 6 - (date.getUTCDay() || 7));
  return date.toISOString().slice(0, 10);
}
export function changesFor(match, values) {
  const changes = {};
  for (const field of ['date', 'time', 'venue']) {
    const value = values[field].trim();
    const original = String(match[field] ?? '');
    const comparable = input => field === 'time' && /^\d{2}:\d{2}$/.test(input) ? `${input}:00` : input;
    if (comparable(value) === comparable(original)) continue;
    if (field === 'date' && !validDate(value)) throw new Error('Renseigner une date valide.');
    if (field === 'time' && !/^([01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$/.test(value)) throw new Error('Renseigner un horaire valide.');
    if (field === 'venue' && (!value || value.length > 200 || /[\x00-\x1f\x7f]/.test(value))) throw new Error('Renseigner une salle de 1 à 200 caractères, sans caractère de contrôle.');
    changes[field] = value;
  }
  if (!Object.keys(changes).length) throw new Error('Aucun changement à enregistrer.');
  return changes;
}
export function groupMatches(rows, team = '') {
  const groups = new Map();
  for (const row of [...rows].filter(row => !team || row.teamId === team).sort((a,b) => `${a.date || '9999'} ${a.time || ''}`.localeCompare(`${b.date || '9999'} ${b.time || ''}`))) {
    const week = weekKey(row.date);
    if (!groups.has(week)) groups.set(week, []);
    groups.get(week).push(row);
  }
  return groups;
}
export function safeFfbbUrl(value) {
  try { const url = new URL(value); return url.protocol === 'https:' && url.hostname === 'competitions.ffbb.com' ? url.href : null; } catch { return null; }
}

export function createApi(config, transport = fetch) {
  let token = null;
  const binding = () => {
    if (!config.binding || config.backendReady === false) throw new Error('Accès aux rencontres indisponible : raccordement et droits en attente de vérification.');
    return config.binding;
  };
  async function request(path, options = {}) {
    let response;
    try { response = await transport(`${config.url}${path}`, {
      ...options, headers: { apikey: config.key, ...(token ? { Authorization: `Bearer ${token}` } : {}), 'Content-Type': 'application/json', ...options.headers }, cache: 'no-store'
    }); } catch { throw new Error('Erreur de connexion : modification non enregistrée. Vérifier le réseau puis actualiser.'); }
    if (!response.ok) {
      if ([401,403].includes(response.status)) throw new Error('Accès refusé : connexion ou autorisation insuffisante.');
      if (response.status === 404) throw new Error('Rencontre introuvable ou service non raccordé.');
      if (response.status === 409) throw new Error('Rencontre modifiée entre-temps : actualiser avant de réessayer.');
      throw new Error(`Service indisponible ou opération refusée (${response.status}). Réessayer ou contacter le club.`);
    }
    return response.status === 204 ? null : response.json();
  }
  async function identity() {
    if (!token) throw new Error('Accès refusé : connexion nécessaire.');
    const user = await request('/auth/v1/user');
    if (!user?.id || user.is_anonymous) throw new Error('Accès refusé : identité non autorisée.');
    return user;
  }
  async function authorize() {
    await identity();
    const b = binding();
    if (b.protocol === 'site-m01-rpc') {
      if (!(await rpc('site_m01_teams', { p_scope: 'management' })).length) throw new Error('Accès refusé : compte non autorisé à gérer les rencontres.');
      return;
    }
    // RPC existante à identifier, sans argument d’adresse fourni par le navigateur.
    // Elle doit vérifier auth.uid() en base, et RLS doit aussi protéger chaque UPDATE.
    if (!b.accessRpc) throw new Error('Accès refusé : contrôle des droits non raccordé.');
    const allowed = await request(`/rest/v1/rpc/${encodeURIComponent(b.accessRpc)}`, { method: 'POST', body: '{}' });
    if (allowed !== true) throw new Error('Accès refusé : compte non autorisé à gérer les rencontres.');
  }
  const query = (table, params) => `/rest/v1/${encodeURIComponent(table)}?${new URLSearchParams(params)}`;
  const rpc = (name, args = {}) => request(`/rest/v1/rpc/${name}`, { method:'POST', body:JSON.stringify(args) });
  async function rpcList(scope, team = null) {
    const rows = [], seen = new Set(); let offset = 0;
    while (true) {
      const page = await rpc('site_m01_list', {p_scope:scope,p_team:team,p_offset:offset,p_limit:500});
      if (!Array.isArray(page)) throw new Error('Réponse des rencontres invalide.');
      for (const row of page) {
        if (row.id == null || row.teamId == null || seen.has(String(row.id)) || (team && String(row.teamId)!==team)) throw new Error('Accès refusé : identifiant ou équipe incohérents.');
        seen.add(String(row.id)); rows.push({...row,id:String(row.id),teamId:String(row.teamId)});
      }
      if (page.length < 500) break;
      offset += page.length;
    }
    return rows;
  }
  async function liveTeams() {
    await identity();
    const root = binding();
    const b = root.live;
    if (root.protocol === 'site-m01-rpc') {
      const teams = await rpc('site_m01_teams',{p_scope:'live'});
      if (!Array.isArray(teams) || teams.some(id=>typeof id!=='string' || !id)) throw new Error('Accès Live refusé : droits invalides.');
      return [...new Set(teams)];
    }
    if (!b?.accessRpc) throw new Error('Accès Live refusé : droits non raccordés.');
    const teams = await request(`/rest/v1/rpc/${encodeURIComponent(b.accessRpc)}`, { method: 'POST', body: '{}' });
    if (!Array.isArray(teams) || teams.some(id => typeof id !== 'string' || !id)) throw new Error('Accès Live refusé : réponse des droits invalide.');
    return [...new Set(teams)];
  }
  async function liveList() {
    const teams = await liveTeams(), root = binding(), b = root.live;
    if (!teams.length) throw new Error('Accès Live refusé : aucune équipe autorisée.');
    if (root.protocol === 'site-m01-rpc') {
      const rows = [];
      for (const team of teams) rows.push(...(await rpcList('live',team)).map(normalizeLive));
      return rows;
    }
    const rows = [], seen = new Set();
    for (const teamId of teams) {
      let offset = 0;
      while (true) {
        const page = await request(query(b.readTable, { select: [...new Set(Object.values(b.read))].join(','), [b.read.teamId]: `eq.${teamId}`, order: `${b.read.id}.asc`, offset, limit: 500 }));
        if (!Array.isArray(page)) throw new Error('Réponse Live invalide.');
        for (const item of page) {
          const row = Object.fromEntries(Object.entries(b.read).map(([key,column]) => [key,item[column]]));
          if (row.id == null || String(row.teamId) !== teamId || seen.has(String(row.id))) throw new Error('Accès Live refusé : rencontre hors du périmètre autorisé.');
          row.id = String(row.id); row.teamId = String(row.teamId); seen.add(row.id);
          rows.push(normalizeLive(row));
        }
        if (page.length < 500) break;
        offset += page.length;
      }
    }
    return rows;
  }
  return {
    async capabilities() {
      await identity(); const b = binding();
      if (b.protocol === 'site-m01-rpc') {
        const management = (await rpc('site_m01_teams',{p_scope:'management'})).length > 0;
        const live = (await liveTeams()).length > 0;
        if (!management && !live) throw new Error('Accès refusé : aucun espace autorisé.');
        return {management,live};
      }
      const management = b.accessRpc ? await request(`/rest/v1/rpc/${encodeURIComponent(b.accessRpc)}`, {method:'POST',body:'{}'}) === true : false;
      const teams = b.live?.accessRpc ? await liveTeams() : [];
      if (!management && !teams.length) throw new Error('Accès refusé : aucun espace autorisé.');
      return { management, live: teams.length > 0 };
    },
    liveList,
    async saveLive(match, patch) {
      if (!config.liveWritesApproved) throw new Error('Modification non enregistrée : écritures Live désactivées en attente de validation Supabase.');
      const teams = await liveTeams();
      if (!teams.includes(match.teamId)) throw new Error('Accès Live refusé pour cette équipe.');
      const fresh = (await liveList()).find(row => row.id === match.id);
      if (!fresh) throw new Error('Rencontre introuvable ou accès retiré.');
      if (fresh.revision == null || fresh.revision !== match.revision) throw new Error('Rencontre modifiée entre-temps : actualiser avant de réessayer.');
      const change = liveChange(fresh, patch), root = binding(), b = root.live;
      if (root.protocol !== 'site-m01-rpc' && (!b?.saveRpc || !b.args)) throw new Error('Modification non enregistrée : raccordement Live non vérifié.');
      const payload = {};
      if (root.protocol !== 'site-m01-rpc') for (const [key,value] of Object.entries({ id: match.id, revision: match.revision, patch: change })) {
        if (!b.args[key]) throw new Error('Arguments Live non vérifiés.');
        payload[b.args[key]] = value;
      }
      // RPC atomique à vérifier : contrôle équipe, règle score et version côté base.
      const saved = root.protocol === 'site-m01-rpc'
        ? await rpc('site_m01_save_live',{p_id:match.id,p_revision:match.revision,p_patch:change})
        : await request(`/rest/v1/rpc/${encodeURIComponent(b.saveRpc)}`, {method:'POST',body:JSON.stringify(payload)});
      if (saved !== true) throw new Error('Modification non enregistrée : enregistrement Live non confirmé.');
      const reread = (await liveList()).find(row => row.id === match.id);
      if (!reread || Object.entries(change).some(([key,value]) => reread[key] !== value)) throw new Error('Réponse reçue, mais relecture Live non confirmée. Actualiser avant de réessayer.');
      return reread;
    },
    async sendCode(email) { await request('/auth/v1/otp', { method: 'POST', body: JSON.stringify({ email, create_user: false }) }); },
    async verifyCode(email, code) {
      const session = await request('/auth/v1/verify', { method: 'POST', body: JSON.stringify({ email, token: code, type: 'email' }) });
      if (!session?.access_token) throw new Error('Connexion refusée : code invalide ou expiré.');
      token = session.access_token;
      await identity();
    },
    async logout() { try { if (token) await request('/auth/v1/logout', { method: 'POST' }); } finally { token = null; } },
    authorize,
    async list() {
      await authorize();
      const b = binding();
      if (b.protocol === 'site-m01-rpc') return rpcList('management');
      // Source privée vérifiée exposant les valeurs effectives et les identifiants réels.
      const rows = []; let offset = 0;
      while (true) {
        const page = await request(query(b.readTable, { select: [...new Set(Object.values(b.read))].join(','), order: `${b.read.id}.asc`, offset, limit: 500 }));
        if (!Array.isArray(page)) throw new Error('Réponse des rencontres invalide.');
        rows.push(...page.map(row => Object.fromEntries(Object.entries(b.read).map(([key, column]) => [key, row[column]]))));
        if (page.length < 500) break;
        offset += page.length;
      }
      const seen = new Set();
      for (const row of rows) {
        if (row.id == null || row.teamId == null || seen.has(String(row.id))) throw new Error('Identifiant de rencontre ou relation équipe invalide.');
        row.id = String(row.id); row.teamId = String(row.teamId); seen.add(row.id);
      }
      return rows;
    },
    async save(match, values) {
      if (!config.writesApproved) throw new Error('Enregistrement désactivé : schéma, droits et validation humaine requis.');
      await authorize();
      const b = binding();
      const changes = changesFor(match, values);
      if (b.protocol === 'site-m01-rpc') {
        if (match.revision == null) throw new Error('Version de rencontre manquante.');
        const saved = await rpc('site_m01_save_management',{p_id:match.id,p_revision:match.revision,p_patch:changes});
        if (saved !== true) throw new Error('Enregistrement non confirmé.');
        const reread = (await rpcList('management',match.teamId)).find(row=>row.id===match.id);
        const publicRow = await rpc('site_m01_public_match',{p_id:match.id});
        const fields={date:'local_date',time:'local_time',venue:'venue_name'};
        const comparable=(key,value)=>key==='time' && /^\d{2}:\d{2}$/.test(value||'') ? `${value}:00` : value;
        if (!reread || !publicRow || Object.entries(changes).some(([key,value])=>comparable(key,reread[key])!==comparable(key,value) || comparable(key,publicRow[fields[key]])!==comparable(key,value))) throw new Error('Correction envoyée, mais propagation publique non confirmée. Actualiser avant de réessayer.');
        return publicRow;
      }
      if (!b.matchId || !b.manual || !b.publicId) throw new Error('Raccordement des corrections non vérifié.');
      const payload = {};
      for (const [key, value] of Object.entries(changes)) {
        if (!b.manual[key]) throw new Error('Champ de correction non vérifié.');
        payload[b.manual[key]] = value;
      }
      // Les champs FFBB sources ne figurent jamais dans le payload.
      const result = await request(query('matches', { [b.matchId]: `eq.${match.id}`, select: b.matchId }), { method: 'PATCH', headers: { Prefer: 'return=representation' }, body: JSON.stringify(payload) });
      if (!Array.isArray(result) || result.length !== 1 || String(result[0][b.matchId]) !== match.id) throw new Error('Enregistrement non confirmé : aucune rencontre autorisée ou réponse ambiguë.');
      const publicRows = await request(query('public_calendar', { [b.publicId]: `eq.${match.id}`, select: 'local_date,local_time,venue_name' }));
      const fields = { date: 'local_date', time: 'local_time', venue: 'venue_name' };
      const normalized = (key, value) => key === 'time' && /^\d{2}:\d{2}$/.test(value || '') ? `${value}:00` : value;
      if (!Array.isArray(publicRows) || publicRows.length !== 1 || Object.entries(changes).some(([key, value]) => normalized(key, publicRows[0][fields[key]]) !== normalized(key, value))) throw new Error('Correction envoyée, mais propagation publique non confirmée. Actualiser avant toute nouvelle tentative.');
      return publicRows[0];
    },
    async setAccess(userId,teamId,rights) {
      if (!config.accessWritesApproved) throw new Error('Configuration des habilitations désactivée.');
      await identity();
      if (binding().protocol!=='site-m01-rpc') throw new Error('Administration non raccordée.');
      if (!rights || ['management','live','enabled'].some(key=>typeof rights[key]!=='boolean')) throw new Error('Droits explicites requis.');
      const result=await rpc('site_m01_set_access',{p_user:userId,p_team:teamId,p_manage:rights.management,p_live:rights.live,p_enabled:rights.enabled});
      if (result!==true) throw new Error('Habilitation non confirmée.');
      return true;
    },
    async listAccess(userId = null, offset = 0) {
      await identity();
      if (binding().protocol !== 'site-m01-rpc') throw new Error('Administration non raccordée.');
      return rpc('site_m01_access_list',{p_user:userId,p_offset:offset,p_limit:100});
    }
  };
}
