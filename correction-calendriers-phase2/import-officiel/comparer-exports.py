#!/usr/bin/env python3
"""Compare deux collectes normalisées localement. Aucun accès réseau/DB ni SQL émis."""
import argparse, collections, json, re
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('ancien',type=Path);p.add_argument('nouveau',type=Path)
a=p.parse_args()
def read(path):
 data=json.loads(path.read_text()); rows=data['candidates'] if isinstance(data,dict) else data
 assert isinstance(rows,list), 'Un tableau candidates normalisé est requis'
 ids=[r['ffbb_match_id'] for r in rows]
 assert all(isinstance(i,str) and re.fullmatch(r'\d+',i) for i in ids), 'ID numérique texte requis'
 assert len(ids)==len(set(ids)), 'ID répété : rapprochement manuel requis'
 groups=collections.defaultdict(list)
 for r in rows:
  assert r['ffbb_match_url'].endswith('/match/'+r['ffbb_match_id']), 'URL et ID incompatibles'
  key=tuple(r[k] for k in ['team_code','phase','pool','round_label','local_date','opponent_name','home_away'])
  groups[key].append(r['ffbb_match_id'])
 ambiguous={i for ids in groups.values() if len(ids)>1 for i in ids}
 return {r['ffbb_match_id']:r for r in rows}, ambiguous
old,_=read(a.ancien);new,ambiguous=read(a.nouveau);plan=[]
identity=['team_code','ffbb_team_id','phase','pool','competition_label','ffbb_match_url','opponent_name','home_away']
fields=identity+['local_date','local_time','starts_local','scheduled_at_ffbb','venue_name','venue_address','round_label','status']
for key,row in new.items():
 before=old.get(key)
 changes={k:{'ancien':before.get(k),'nouveau':row.get(k)} for k in fields if before and before.get(k)!=row.get(k)}
 blocked=key in ambiguous or bool(row.get('issues')) or row.get('publishable_after_review') is not True
 status='ambigu_ou_source_a_controler' if blocked else 'nouvel_id_a_valider' if before is None else 'identite_a_rapprocher' if any(k in changes for k in identity) else 'changement_a_revoir' if changes else 'source_identique'
 plan.append({'ffbb_match_id':key,'team_code':row['team_code'],'statut':status,'changements':changes})
for key in old.keys()-new.keys():plan.append({'ffbb_match_id':key,'statut':'absent_du_nouvel_export_ne_pas_supprimer'})
print(json.dumps({'portee':'comparaison des sources uniquement ; état DB et corrections club non évalués','ecriture':False,'plan':plan},ensure_ascii=False,indent=2))
