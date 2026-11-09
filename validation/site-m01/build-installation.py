"""Assembler la proposition atomique, sans connexion ni exécution SQL.
Les corps des scripts validés sont conservés ; seuls leurs BEGIN/COMMIT externes
sont remplacés par une transaction unique. Arrêt séparé : 03-disable.sql.
"""
import hashlib
import re
from pathlib import Path
COMPONENTS = ['01-access-live.sql','01a-rls-executor.sql','02-configure.sql','05-verify-installation.sql']

def build():
    root = Path(__file__).parent / 'sql'
    parts = ['-- INSTALLATION ATOMIQUE PROPOSÉE pour fgswygeqstgagmipltpq.\n-- Ne pas exécuter sans validation humaine. Aucun compte/droit métier créé.\n-- Source : build-installation.py ; 03-disable.sql reste séparé.\nBEGIN;\n']
    for name in COMPONENTS:
        source = (root / name).read_text()
        # Formes externes connues et vérifiées, jamais des remplacements dans les corps.
        begin = list(re.finditer(r'^BEGIN(?: READ ONLY)?;$', source, re.M))
        end = list(re.finditer(r'^COMMIT;$', source, re.M))
        if len(begin) != 1 or len(end) != 1 or begin[0].start() >= end[0].start():
            raise ValueError('Transaction externe inattendue : ' + name)
        body = source[:begin[0].start()] + source[begin[0].end():end[0].start()] + source[end[0].end():]
        digest = hashlib.sha256(source.encode()).hexdigest()
        parts.append(f'\n-- Composant : {name}\n-- SHA256 : {digest}\n' + body + '\n')
    parts.append("\n-- Rafraîchir PostgREST seulement si toute la transaction est validée.\nNOTIFY pgrst, 'reload schema';\nCOMMIT;\n")
    return ''.join(parts)

if __name__ == '__main__':
    target = Path(__file__).parent / 'sql' / 'INSTALLATION.sql'
    target.write_text(build())
    print('Proposition générée, aucune exécution : ' + str(target))
