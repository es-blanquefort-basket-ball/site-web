"""Tests HTTP de la simulation démarrée sur 127.0.0.1:8872, jamais Supabase."""
import json
from urllib.request import Request, urlopen
from urllib.error import HTTPError
BASE = 'http://127.0.0.1:8872'
count=0
def call(path,profile=None,body=None,method=None):
 headers={'Content-Type':'application/json'}
 if profile: headers['Authorization']='Bearer TEST_'+profile
 req=Request(BASE+path,headers=headers,data=None if body is None else json.dumps(body).encode(),method=method)
 try:
  with urlopen(req) as response: return response.status,json.load(response)
 except HTTPError as error: return error.code,None
def check(condition,name):
 global count
 assert condition,name
 count+=1;print('OK HTTP simulation : '+name)
check(call('/rest/v1/TEST_ONLY_LIVE?teamId=eq.TEST-U11-M1')[0]==403,'sans session refusé')
check(call('/rest/v1/rpc/TEST_ONLY_ACCESS','live',{})==(200,False),'référent Live sans gestion')
check(call('/rest/v1/TEST_ONLY_MATCHES','live')[0]==403,'lecture gestion interdite au référent')
check(call('/rest/v1/rpc/TEST_ONLY_LIVE_TEAMS','gestion',{})==(200,[]),'gestion seule sans Live implicite')
check(call('/rest/v1/TEST_ONLY_LIVE?teamId=eq.TEST-U11-M2','live')[0]==403,'équipe non autorisée refusée')
for team in ['TEST-U11-M2','TEST-U9']:
 status,rows=call('/rest/v1/TEST_ONLY_LIVE?teamId=eq.'+team,'mini')
 check(status==200 and all('clubScore' not in r and 'opponentScore' not in r for r in rows),'aucun score dans la réponse '+team)
 row=rows[0]
 check(call('/rest/v1/rpc/TEST_ONLY_SAVE_LIVE','mini',dict(id=row['id'],revision=row['revision'],patch=dict(clubScore=1,opponentScore=2)))[0]==403,'score interdit côté serveur '+team)
status,rows=call('/rest/v1/TEST_ONLY_LIVE?teamId=eq.TEST-U11-M1','live'); row=rows[0]
check(call('/rest/v1/rpc/TEST_ONLY_SAVE_LIVE','live',dict(id='INCONNU',revision=0,patch=dict(stage=1)))[0]==404,'rencontre introuvable')
check(call('/rest/v1/rpc/TEST_ONLY_SAVE_LIVE','live',dict(id=row['id'],revision=-1,patch=dict(stage=1)))[0]==409,'conflit de version')
check(call('/rest/v1/rpc/TEST_ONLY_SAVE_LIVE','live',dict(id=row['id'],revision=row['revision'],patch=dict(clubScore=-1,opponentScore=0)))[0]==400,'score invalide refusé côté serveur')
check(call('/rest/v1/matches','autorise',{},method='PATCH')[0]==403,'écritures organisationnelles verrouillées')
print(str(count)+' contrôles HTTP locaux réussis.')
