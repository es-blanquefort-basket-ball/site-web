import { parseHTML } from "npm:linkedom@0.18.12";
import { DateTime } from "npm:luxon@3.7.2";
import { TARGETS } from "./targets.mjs";

const HOST = "competitions.ffbb.com";
export const HEADERS = Object.freeze({
  "User-Agent": "Mozilla/5.0 ESB-Basket-FFBB-Sync/1.0",
  "Accept": "text/html",
});
const MONTHS = {"janv.":1,"févr.":2,"mars":3,"avr.":4,"mai":5,"juin":6,"juil.":7,"août":8,"sept.":9,"oct.":10,"nov.":11,"déc.":12};
const clean = value => String(value ?? "").replace(/\s+/g," ").trim();
export function selectTargets(codes = TARGETS.map(t=>t.code)) {
  if (!Array.isArray(codes) || codes.length===0 || codes.length>4 || new Set(codes).size!==codes.length
      || codes.some(code=>!TARGETS.some(t=>t.code===code))) throw new Error("Équipes non autorisées");
  return TARGETS.filter(t=>codes.includes(t.code));
}
export function isPhase2Team(team) {
  return TARGETS.some(t=>t.code===team.code && t.teamId===team.ffbb_team_id);
}
function safeUrl(value,base) {
  const url=new URL(value,base);
  if(url.protocol!=="https:" || url.hostname!==HOST || url.port || url.username || url.password) throw new Error("Destination FFBB non autorisée");
  return url;
}
export async function fetchHtml(url, fetcher=fetch) {
  let current=safeUrl(url); const started=Date.now();
  try {
    for(let redirects=0;redirects<=3;redirects++) {
      const response=await fetcher(current.href,{headers:HEADERS,redirect:"manual",signal:AbortSignal.timeout(15000)});
      if([301,302,303,307,308].includes(response.status)) {
        const location=response.headers.get("location");
        if(!location) throw new Error("Redirection sans destination");
        await response.body?.cancel(); current=safeUrl(location,current.href); continue;
      }
      const meta={url:current.href,http_status:response.status,elapsed_ms:Date.now()-started};
      if(!response.ok) { await response.body?.cancel(); return {...meta,ok:false,error:`FFBB_HTTP_${response.status}`,html:null}; }
      if(!/text\/html|application\/xhtml\+xml/i.test(response.headers.get("content-type")||"")) {
        await response.body?.cancel(); return {...meta,ok:false,error:"NOT_HTML",html:null};
      }
      // Limite effective pendant la lecture, pas seulement après allocation du corps.
      const reader=response.body?.getReader(); let bytes=0; const chunks=[];
      if(!reader) throw new Error("Réponse sans corps");
      for(;;){const {done,value}=await reader.read();if(done)break;bytes+=value.byteLength;
        if(bytes>4*1024*1024){await reader.cancel();throw new Error("HTML trop volumineux");}chunks.push(value);}
      const raw=new Uint8Array(bytes);let offset=0;for(const chunk of chunks){raw.set(chunk,offset);offset+=chunk.length;}
      return {...meta,ok:true,error:null,html:new TextDecoder().decode(raw),bytes};
    }
    throw new Error("Trop de redirections");
  } catch(error) {return {url:current.href,http_status:null,elapsed_ms:Date.now()-started,ok:false,error:error?.name==="TimeoutError"?"TIMEOUT":"FETCH_FAILED",html:null};}
}
function documentOf(html){
  const {document}=parseHTML(html);
  document.querySelectorAll("script,style,noscript,header,footer").forEach(e=>e.remove());
  return document;
}
function textOf(node){const pending=[node],texts=[];
  while(pending.length){const n=pending.pop();if(n.nodeType===3){texts.push(n.textContent);continue;}
    for(let i=n.childNodes.length-1;i>=0;i--)pending.push(n.childNodes[i]);}
  return clean(texts.join(" "));
}
export function extractMatchLinks(html,target) {
  const doc=documentOf(html);const prefix=new URL(target.poolUrl).pathname+"/match/";const links=new Map();
  for(const a of doc.querySelectorAll("a[href]")) {
    try {const url=safeUrl(a.getAttribute("href"),target.teamUrl);
      if(!url.pathname.startsWith(prefix))continue;
      const id=url.pathname.slice(prefix.length);
      if(!/^\d+$/.test(id))continue;
      url.search="";url.hash="";links.set(id,url.href);
    } catch { /* Lien externe ou sans rapport : ignoré, jamais suivi. */ }
  }
  return [...links].map(([id,url])=>({id,url}));
}
export function parseMatchDetail(html,link,target) {
  const doc=documentOf(html);const text=textOf(doc.body?.childNodes.length?doc.body:doc);
  if(/(?:^|\s)(?:ANNUL[ÉE]E?|REPORT[ÉE]E?|FORFAIT)(?=\s|$)/i.test(text))throw new Error("MATCH_STATUS_REVIEW");
  const phaseRefs=[...doc.querySelectorAll("a[href]")].map(a=>{try{return safeUrl(a.getAttribute("href"),link.url);}catch{return null;}})
    .filter(u=>u?.pathname===new URL(target.poolUrl).pathname && u.searchParams.has("phase") && u.searchParams.has("poule"));
  const matchingNumericRef=phaseRefs.some(u=>u.searchParams.get("phase")===target.phase && u.searchParams.get("poule")===target.pool);
  // Les fiches réelles n'ont souvent pas les IDs phase/poule dans le fil d'Ariane.
  // Dans ce cas, la page équipe vérifiée fournit ces IDs ; la fiche doit confirmer phase et lettre de poule.
  const breadcrumbs=[...doc.querySelectorAll("a[href]")].filter(a=>{
    try{return safeUrl(a.getAttribute("href"),link.url).pathname===new URL(target.poolUrl).pathname;}catch{return false;}});
  const fallbackRef=phaseRefs.length===0 && breadcrumbs.some(a=>/phase\s*2/i.test(a.textContent))
    && new RegExp(`POULE\\s+${target.poolLabel}\\s*[-–—]`,"i").test(text);
  if(!matchingNumericRef&&!fallbackRef)throw new Error("PHASE_POOL_UNVERIFIED");
  const heading=/POULE\s+.+?\s*[-–—]\s*JOURN[ÉE]E\s+(\d+)/i.exec(text);
  if(!heading)throw new Error("ROUND_UNVERIFIED");
  const after=text.slice(heading.index+heading[0].length);
  const date=/(\d{1,2})\s+(JANV\.|F[ÉE]VR\.|MARS|AVR\.|MAI|JUIN|JUIL\.|AO[ÛU]T|SEPT\.|OCT\.|NOV\.|D[ÉE]C\.)(?:\s+(\d{2})H(\d{2}))?/i.exec(after);
  if(!date)throw new Error("DATE_UNVERIFIED");
  const label=date[2].toLowerCase().replace("fevr.","févr.").replace("aout","août").replace("dec.","déc.");
  const month=MONTHS[label];const year=month>=9?target.seasonStart:target.seasonStart+1;
  const day=DateTime.fromObject({year,month,day:Number(date[1])},{zone:"Europe/Paris"});
  if(!day.isValid)throw new Error("INVALID_DATE");
  const hm=date[3]===undefined?null:`${date[3]}:${date[4]}`;
  if(hm && !DateTime.fromISO(`${day.toISODate()}T${hm}`,{zone:"Europe/Paris"}).isValid)throw new Error("INVALID_TIME");
  const time=hm==="00:00"?null:hm;
  const suspicious=hm!==null && /^(01|02):/.test(hm);
  // Les deux clubs doivent être lus dans la zone du match, sans supposer le sens domicile/extérieur.
  const scoreboard=after.slice(date.index+date[0].length).split(/\bSalle\b/i)[0].trim();
  const teams=/^(.+?)\s+(-\s*-|\d+\s+\d+)\s+(.+?)$/.exec(scoreboard);
  if(!teams)throw new Error("TEAMS_UNVERIFIED");
  const home=clean(teams[1]),away=clean(teams[3]);
  const homeClub=home.toUpperCase()===target.clubName,awayClub=away.toUpperCase()===target.clubName;
  if(homeClub===awayClub)throw new Error("CLUB_IDENTITY_UNVERIFIED");
  const venueText=text.split(/\bSalle\b/i)[1]?.split(/\bTéléphone\b|À LIRE AUSSI/i)[0]||"";
  const venueName=/\bNom\s+(.+?)(?=\s+Adresse\b|$)/i.exec(venueText);
  const venueAddress=/\bAdresse\s+(.+)$/i.exec(venueText);
  if(!new RegExp(`/match/${link.id}$`).test(link.url))throw new Error("MATCH_ID_UNVERIFIED");
  return {team_code:target.code,ffbb_team_id:target.teamId,competition_label:target.competition,phase:target.phase,pool:target.pool,
    ffbb_match_id:link.id,ffbb_match_url:link.url,ffbb_team_url:target.teamUrl,ffbb_pool_url:target.poolUrl,
    local_date:day.toISODate(),local_time:time,starts_local:time?`${day.toISODate()}T${time}:00`:null,
    scheduled_at_ffbb:time?DateTime.fromISO(`${day.toISODate()}T${time}`,{zone:"Europe/Paris"}).toUTC().toISO():null,
    opponent_name:homeClub?away:home,home_away:homeClub?"home":"away",round_label:`J${heading[1]}`,
    venue_name:venueName?clean(venueName[1]):null,venue_address:venueAddress?clean(venueAddress[1]):null,
    status:"scheduled",issues:[...(suspicious?["SUSPICIOUS_TIME"]:[]),...(/^\d/.test(teams[2])?["RESULT_REQUIRES_REVIEW"]:[])],published:false};
}
export function classifyCandidates(rows) {
  const groups=new Map();
  for(const row of rows){const key=[row.team_code,row.phase,row.pool,row.round_label,row.local_date,row.opponent_name,row.home_away].join("|");
    if(!groups.has(key))groups.set(key,[]);groups.get(key).push(row);}
  return rows.map(row=>{const key=[row.team_code,row.phase,row.pool,row.round_label,row.local_date,row.opponent_name,row.home_away].join("|");
    const peers=groups.get(key);const issues=[...row.issues];
    if(new Set(peers.map(r=>r.ffbb_match_id)).size>1)issues.push("MULTIPLE_OFFICIAL_IDS");
    return {...row,issues,review_required:true,publishable_after_review:issues.length===0};});
}
export function summarize(reports) {
  const failures=reports.filter(r=>!r.ok).length;
  const status=reports.length===0||failures===reports.length?"error":failures>0?"warning":"success";
  return {success:status==="success",status,failed_teams:failures,teams:reports};
}
export async function runPhase2({mode="probe",codes}={},fetcher=fetch) {
  if(!["probe","preview"].includes(mode))throw new Error("Mode non autorisé");
  const targets=selectTargets(codes);const reports=[];const all=[];const deadline=Date.now()+90000;
  for(const target of targets){
    if(Date.now()>=deadline){reports.push({team:target.code,ok:false,error:"TOTAL_BUDGET_EXCEEDED",http_status:null});continue;}
    const response=await fetchHtml(target.teamUrl,fetcher);
    const report={team:target.code,url:response.url,http_status:response.http_status,ok:false,error:response.error,match_pages:0};
    if(!response.ok){reports.push(report);continue;}
    const teamDoc=documentOf(response.html);
    const poolVerified=[...teamDoc.querySelectorAll("a[href]")].some(a=>{
      try {const u=safeUrl(a.getAttribute("href"),target.teamUrl);return u.pathname===new URL(target.poolUrl).pathname
        && u.searchParams.get("phase")===target.phase && u.searchParams.get("poule")===target.pool;}catch{return false;}});
    if(!poolVerified){report.error="PHASE_POOL_UNVERIFIED";reports.push(report);continue;}
    const links=extractMatchLinks(response.html,target);
    report.match_pages=links.length;
    if(links.length===0||links.length>40){report.error=links.length===0?"EMPTY_OR_UNPARSEABLE_CALENDAR":"TOO_MANY_MATCHES";reports.push(report);continue;}
    if(mode==="probe"){report.ok=true;report.error=null;reports.push(report);continue;}
    let detailErrors=0;const teamRows=[];const detailFailures=[];
    for(const link of links){if(Date.now()>=deadline){detailErrors++;detailFailures.push({error:"TOTAL_BUDGET_EXCEEDED"});break;}const detail=await fetchHtml(link.url,fetcher);
      if(!detail.ok){detailErrors++;detailFailures.push({match_id:link.id,http_status:detail.http_status,error:detail.error});continue;}
      try{teamRows.push(parseMatchDetail(detail.html,link,target));}catch(error){detailErrors++;detailFailures.push({match_id:link.id,http_status:detail.http_status,error:error.message});}}
    report.ok=detailErrors===0;report.error=detailErrors?"MATCH_DETAILS_INCOMPLETE":null;
    report.detail_errors=detailErrors;report.detail_failures=detailFailures;report.candidates=teamRows.length;reports.push(report);
    // Pas de candidats importables d'une équipe partiellement lue : collisions potentielles inconnues.
    if(report.ok)all.push(...teamRows);
  }
  const candidates=classifyCandidates(all);const summary=summarize(reports);
  if(summary.status==="success" && candidates.some(r=>r.issues.length)) {summary.status="warning";summary.success=false;}
  return {...summary,mode,execution_environment:"not_attested",production_write:false,candidates};
}
export async function handleReadOnly(body,fetcher=fetch) {
  try{const result=await runPhase2(body,fetcher);return Response.json(result,{status:result.status==="error"?502:result.status==="warning"?207:200});}
  catch{return Response.json({success:false,status:"error",error:"INVALID_REQUEST",production_write:false},{status:400});}
}
