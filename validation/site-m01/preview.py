"""Simulation locale sans Supabase : python3 validation/site-m01/preview.py.
Comptes @example.test : autorise (gestion+Live), live (Live M1), mini (Live M2/U9),
gestion (gestion seule), refuse (aucun droit). Code fictif : 123456.
Les écritures Live sont seulement en mémoire. Ne pas publier ce serveur.
"""
import json
from copy import deepcopy
from pathlib import Path
from threading import Lock
from urllib.parse import urlparse, parse_qs
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from functools import partial
ROOT = Path(__file__).resolve().parents[2]
BASE_FIELDS = ['id', 'teamId', 'teamLabel', 'opponent', 'date', 'time', 'venue', 'homeAway', 'ffbbMatchUrl', 'ffbbTeamUrl']
LIVE_FIELDS = BASE_FIELDS + ['stage', 'clubScore', 'opponentScore', 'scorePolicy', 'competitionCode', 'revision']
BINDING = dict(accessRpc='TEST_ONLY_ACCESS', readTable='TEST_ONLY_MATCHES', read={k:k for k in BASE_FIELDS},
 live=dict(accessRpc='TEST_ONLY_LIVE_TEAMS', readTable='TEST_ONLY_LIVE', read={k:k for k in LIVE_FIELDS}, saveRpc='TEST_ONLY_SAVE_LIVE', args=dict(id='id',revision='revision',patch='patch')))
ROWS = [dict(id='TEST-M1', teamId='TEST-U11-M1', teamLabel='U11 M1 — TEST DMU11-4-P2', competitionCode='DMU11-4-P2', scorePolicy='numeric', opponent='ADVERSAIRE TEST A', date='2026-11-07', time='14:30:00', venue='SALLE TEST', homeAway='home'),
 dict(id='TEST-M2', teamId='TEST-U11-M2', teamLabel='U11 M2 — TEST DMU11-10-P2', competitionCode='DMU11-10-P2', scorePolicy='minibasket-no-score', opponent='ADVERSAIRE TEST B', date='2026-11-08', time=None, venue=None, homeAway='away'),
 dict(id='TEST-U9', teamId='TEST-U9', teamLabel='U9 — TEST', competitionCode='TEST-U9', scorePolicy='u9-no-score', opponent='ADVERSAIRE TEST C', date='2026-11-14', time='10:00:00', venue='SALLE TEST', homeAway='home'),
 dict(id='TEST-SANS-DATE', teamId='TEST-U9', teamLabel='U9 — TEST', competitionCode='TEST-U9', scorePolicy='u9-no-score', opponent=None, date=None, time=None, venue=None, homeAway=None)]
for row in ROWS: row.update(stage=0,clubScore=None,opponentScore=None,revision=0)
TEAMS = {'autorise':['TEST-U11-M1','TEST-U11-M2','TEST-U9'], 'live':['TEST-U11-M1'], 'mini':['TEST-U11-M2','TEST-U9'], 'gestion':[], 'refuse':[]}
LOCK = Lock()
class Handler(SimpleHTTPRequestHandler):
 def profile(self): return self.headers.get('Authorization','').removeprefix('Bearer TEST_')
 def answer(self, data, status=200, mime='application/json'):
  self.send_response(status); self.send_header('Content-Type',mime); self.send_header('Cache-Control','no-store'); self.end_headers()
  self.wfile.write((json.dumps(data) if mime=='application/json' else data).encode())
 def do_GET(self):
  path=urlparse(self.path).path; args=parse_qs(urlparse(self.path).query); who=self.profile()
  if path=='/app/gestion-matchs-config.js':
   return self.answer('export const config = '+json.dumps(dict(url='http://127.0.0.1:8872',key='TEST_ONLY',binding=BINDING,writesApproved=False,liveWritesApproved=True,simulation=True)),mime='text/javascript')
  if path=='/auth/v1/user': return self.answer(dict(id='TEST_'+who)) if who in TEAMS else self.answer({},401)
  if path=='/rest/v1/TEST_ONLY_MATCHES':
   return self.answer(ROWS) if who in ['autorise','gestion'] else self.answer({},403)
  if path=='/rest/v1/TEST_ONLY_LIVE':
   team=args.get('teamId',[''])[0].removeprefix('eq.')
   if team not in TEAMS.get(who,[]): return self.answer({},403)
   with LOCK:
    rows=deepcopy([r for r in ROWS if r['teamId']==team])
   for row in rows:
    if row['scorePolicy']!='numeric': row.pop('clubScore',None); row.pop('opponentScore',None)
   return self.answer(rows)
  if path=='/app/gestion-matchs.html':
   html=(ROOT/'app/gestion-matchs.html').read_text()
   notice='<p class="notice">SIMULATION LOCALE — aucune donnée Supabase. Comptes autorise@example.test (gestion + Live), live@example.test (Live M1), mini@example.test (Live M2/U9), gestion@example.test (gestion), refuse@example.test (refus). Code : 123456. Live enregistré uniquement en mémoire.</p>'
   return self.answer(html.replace('<main class="wrap">','<main class="wrap">'+notice),mime='text/html; charset=utf-8')
  return super().do_GET()
 def do_POST(self):
  body=json.loads(self.rfile.read(int(self.headers.get('Content-Length',0))) or '{}'); who=self.profile()
  if self.path=='/auth/v1/otp': return self.answer({})
  if self.path=='/auth/v1/verify':
   email=body.get('email',''); account=email.split('@')[0]
   if body.get('token')!='123456' or email!=account+'@example.test' or account not in TEAMS: return self.answer({},403)
   return self.answer(dict(access_token='TEST_'+account))
  if self.path=='/rest/v1/rpc/TEST_ONLY_ACCESS': return self.answer(who in ['autorise','gestion'])
  if self.path=='/rest/v1/rpc/TEST_ONLY_LIVE_TEAMS': return self.answer(TEAMS.get(who,[]))
  if self.path=='/rest/v1/rpc/TEST_ONLY_SAVE_LIVE':
   with LOCK:
    row=next((r for r in ROWS if r['id']==body.get('id')),None)
    if row is None: return self.answer({},404)
    if row['teamId'] not in TEAMS.get(who,[]): return self.answer({},403)
    if body.get('revision')!=row['revision']: return self.answer({},409)
    patch=body.get('patch',{})
    if set(patch)=={'stage'}:
     if type(patch['stage']) is not int or not 0<=patch['stage']<=6: return self.answer({},400)
    elif set(patch)=={'clubScore','opponentScore'}:
     if row['scorePolicy']!='numeric' or row['competitionCode']=='DMU11-10-P2': return self.answer({},403)
     if any(v is not None and (type(v) is not int or not 0<=v<=2147483647) for v in patch.values()): return self.answer({},400)
    else: return self.answer({},400)
    row.update(patch); row['revision']+=1
   return self.answer(True)
  if self.path=='/auth/v1/logout': return self.answer({})
  return self.answer({},403)
 def do_PATCH(self): return self.answer({},403)
if __name__=='__main__':
 print('SIMULATION : http://127.0.0.1:8872/app/gestion-matchs.html',flush=True)
 ThreadingHTTPServer(('127.0.0.1',8872),partial(Handler,directory=str(ROOT))).serve_forever()
