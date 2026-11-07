"""Prépare, sans exécution, le patch de salle depuis pg_get_viewdef.
Dépendance de développement : pglast==7.22 (jamais requise par le site).
Usage : python calendar-view-patch.py definition.sql > proposition.sql
Le SQL généré exige que la définition réelle soit toujours identique et conserve
une sauvegarde privée avant CREATE OR REPLACE VIEW. Aucune connexion réseau.
"""
import sys
from pathlib import Path
from pglast import ast, parse_sql
from pglast.stream import RawStream


def prepare(source):
    statements = parse_sql(source)
    if len(statements) != 1 or not isinstance(statements[0].stmt, ast.SelectStmt):
        raise ValueError('Fournir uniquement le SELECT exact retourné par pg_get_viewdef.')
    root = statements[0].stmt
    edits = 0

    def fields(value):
        if isinstance(value, ast.ColumnRef) and all(isinstance(x, ast.String) for x in value.fields):
            return tuple(x.sval for x in value.fields)
        return ()

    def rewrite(value, aliases, unqualified=False):
        nonlocal edits
        column = fields(value)
        if column and column[-1] == 'venue_name_raw':
            if len(column) == 2 and column[0] in aliases:
                prefix = column[:-1]
            elif len(column) == 1 and unqualified:
                prefix = ()
            else:
                raise ValueError('Origine de venue_name_raw ambiguë : correction manuelle ciblée nécessaire.')
            override = ast.ColumnRef(fields=tuple(ast.String(sval=x) for x in (*prefix, 'venue_name_override')))
            edits += 1
            return ast.CoalesceExpr(args=(override, value))
        if isinstance(value, ast.CoalesceExpr) and len(value.args) == 2:
            first, second = fields(value.args[0]), fields(value.args[1])
            if first and second and first[-1] == 'venue_name_override' and second[-1] == 'venue_name_raw' and first[:-1] == second[:-1]:
                return value  # branche déjà corrigée
        if isinstance(value, ast.SubLink) or isinstance(value, ast.SelectStmt):
            raise ValueError('Sous-requête dans la salle : refus de transformation automatique.')
        if isinstance(value, ast.Node):
            for name in value:
                child = getattr(value, name)
                if isinstance(child, ast.Node):
                    setattr(value, name, rewrite(child, aliases, unqualified))
                elif isinstance(child, tuple):
                    setattr(value, name, tuple(rewrite(x, aliases, unqualified) if isinstance(x, ast.Node) else x for x in child))
        return value

    def leaf(select):
        return leaf(select.larg) if select.larg else select

    columns = leaf(root).targetList
    positions = [i for i, target in enumerate(columns or ()) if target.name == 'venue_name']
    if len(positions) != 1:
        raise ValueError('Colonne de sortie venue_name non identifiée de façon unique.')
    position = positions[0]

    def visit(select):
        if select.withClause:
            raise ValueError('CTE dans la vue : vérifier les sources avant transformation.')
        if select.larg:
            visit(select.larg)
            visit(select.rarg)
            return
        aliases = set()
        ranges = []
        def scan(value):
            if isinstance(value, ast.RangeVar):
                ranges.append(value)
                if value.relname == 'matches' and value.schemaname in (None, 'public'):
                    aliases.add(value.alias.aliasname if value.alias else 'matches')
            elif isinstance(value, ast.JoinExpr):
                scan(value.larg)
                scan(value.rarg)
            else:
                raise ValueError('Source FROM complexe : vérifier la branche manuellement.')
        for source_range in select.fromClause or ():
            scan(source_range)
        if position >= len(select.targetList or ()):
            raise ValueError('Branches UNION incompatibles.')
        target = select.targetList[position]
        # Ne modifier que la colonne salle, jamais les autres projections ou filtres.
        target.val = rewrite(target.val, aliases, len(ranges) == 1 and len(aliases) == 1)
    visit(root)
    if not edits:
        raise ValueError('Aucune projection de salle brute à corriger.')
    patched = RawStream()(root)
    quote = lambda text: "'" + text.replace("'", "''") + "'"
    # pg_get_viewdef retourne une forme canonique ; comparaison avant DDL et verrou.
    return f'''-- PROPOSITION NON EXÉCUTÉE : {edits} expression(s) salle corrigée(s).
BEGIN;
LOCK TABLE public.public_calendar IN ACCESS EXCLUSIVE MODE;
DO $guard$ BEGIN
 IF pg_get_viewdef('public.public_calendar'::regclass,true) <> {quote(source)} THEN
  RAISE EXCEPTION 'La vue a changé : régénérer le patch depuis sa définition actuelle';
 END IF;
END $guard$;
CREATE TABLE IF NOT EXISTS site_m01.view_backup (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 saved_at timestamptz NOT NULL DEFAULT clock_timestamp(), definition text NOT NULL,
 view_options text[]
);
ALTER TABLE site_m01.view_backup ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON site_m01.view_backup FROM PUBLIC,anon,authenticated;
INSERT INTO site_m01.view_backup(definition,view_options)
 SELECT {quote(source)},reloptions FROM pg_class WHERE oid='public.public_calendar'::regclass;
DO $replace$ DECLARE options text[]; BEGIN
 SELECT reloptions INTO options FROM pg_class WHERE oid='public.public_calendar'::regclass;
 -- CREATE OR REPLACE peut réinitialiser reloptions : les réappliquer explicitement.
 EXECUTE 'CREATE OR REPLACE VIEW public.public_calendar'
  || CASE WHEN cardinality(options)>0 THEN ' WITH ('||array_to_string(options,',')||')' ELSE '' END
  || ' AS ' || {quote(patched)};
END $replace$;
COMMIT;
'''


if __name__ == '__main__':
    try:
        sys.stdout.write(prepare(Path(sys.argv[1]).read_text()))
    except (ValueError, IndexError) as error:
        sys.exit(str(error))
