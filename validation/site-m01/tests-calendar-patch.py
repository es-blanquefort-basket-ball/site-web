"""Tests du générateur AST, sans connexion ni modification en production."""
import importlib.util
import sys
sys.dont_write_bytecode = True
from pathlib import Path
s=importlib.util.spec_from_file_location('patch',Path(__file__).with_name('calendar-view-patch.py'))
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
count=0
def check(condition,name):
 global count
 assert condition,name
 count+=1
 print('OK AST : '+name)
source='SELECT m.id, m.venue_name_raw AS venue_name FROM public.matches m UNION ALL SELECT n.id, COALESCE(n.venue_name_override,n.venue_name_raw) FROM public.matches n;'
out=m.prepare(source);ddl=out.split("|| ' AS ' ||")[1]
check(ddl.count('COALESCE(')==2,'une branche brute corrigée, autre déjà corrigée conservée')
check('m.venue_name_override' in ddl,'override manuel prioritaire')
check('pg_get_viewdef' in out and 'view_backup' in out,'précondition et sauvegarde privées')
case='SELECT m.id, CASE WHEN m.id IS NOT NULL THEN m.venue_name_raw ELSE NULL END AS venue_name FROM public.matches m;'
check('COALESCE(m.venue_name_override, m.venue_name_raw)' in m.prepare(case).split("|| ' AS ' ||")[1],'branche CASE salle corrigée')
untouched='SELECT m.venue_name_raw AS original_raw, m.venue_name_raw AS venue_name FROM public.matches m;'
check('m.venue_name_raw AS original_raw' in m.prepare(untouched).split("|| ' AS ' ||")[1],'autres projections intactes')
for bad in ['SELECT x.venue_name_raw AS venue_name FROM public.teams x;',
 'SELECT venue_name_raw AS venue_name FROM public.matches m JOIN public.teams t ON true;',
 'DELETE FROM public.matches;',
 'SELECT m.venue_name_raw AS venue_name FROM public.matches m; SELECT 1;']:
 try: m.prepare(bad)
 except ValueError: check(True,'source ambiguë ou requête hors périmètre refusée')
 else: raise AssertionError(bad)

# Définition réelle reçue : seules les trois projections de salle diffèrent.
import json
from pglast import parse_sql
from pglast.stream import RawStream
root=Path(__file__).parent
reference=json.loads((root/'reference/schema-received.json').read_text())
source=reference['calendar_definition']
check(source.count('m.venue_name_raw AS venue_name')==3,'trois branches brutes dans la définition réelle')
patch=m.prepare(source,reference['calendar_options'])
literal=patch.split("|| ' AS ' ||",1)[1].split(';\nEND $replace$;',1)[0].strip()
actual=literal[1:-1].replace("''", "'")
expected=source.replace('m.venue_name_raw AS venue_name','COALESCE(m.venue_name_override, m.venue_name_raw) AS venue_name')
check(RawStream()(parse_sql(actual))==RawStream()(parse_sql(expected)),'AST réel identique sauf les trois COALESCE attendus')
check(patch==(root/'sql/04-public-calendar-venue.sql').read_text(),'script final reproductible et garde security_invoker=true')
print(str(count)+' contrôles AST réussis au total.')
