"""Aperçu local uniquement : python3 validation/site-m01/preview.py.
Compte autorisé : autorise@example.test / 123456 ; refusé : refuse@example.test.
Aucun appel Supabase. Ne jamais publier ce serveur ni ses données de test.
"""
import json
from pathlib import Path
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from functools import partial
ROOT = Path(__file__).resolve().parents[2]
BINDING = dict(accessRpc='TEST_ONLY_ACCESS', readTable='TEST_ONLY_MATCHES',
               read={k: k for k in ['id', 'teamId', 'teamLabel', 'opponent', 'date', 'time', 'venue', 'homeAway', 'ffbbMatchUrl', 'ffbbTeamUrl']})
ROWS = [dict(id='TEST-M1', teamId='TEST-U11-M1', teamLabel='U11 M1 — TEST DMU11-4-P2', opponent='ADVERSAIRE TEST A', date='2026-11-07', time='14:30:00', venue='SALLE TEST', homeAway='home'),
        dict(id='TEST-M2', teamId='TEST-U11-M2', teamLabel='U11 M2 — TEST DMU11-10-P2', opponent='ADVERSAIRE TEST B', date='2026-11-08', time=None, venue=None, homeAway='away'),
        dict(id='TEST-U9', teamId='TEST-U9', teamLabel='U9 — TEST', opponent='ADVERSAIRE TEST C', date='2026-11-14', time='10:00:00', venue='SALLE TEST', homeAway='home'),
        dict(id='TEST-SANS-DATE', teamId='TEST-U9', teamLabel='U9 — TEST', opponent=None, date=None, time=None, venue=None, homeAway=None)]
class Handler(SimpleHTTPRequestHandler):
    def answer(self, data, status=200, mime='application/json'):
        self.send_response(status); self.send_header('Content-Type', mime)
        self.send_header('Cache-Control', 'no-store'); self.end_headers()
        self.wfile.write((json.dumps(data) if mime == 'application/json' else data).encode())
    def do_GET(self):
        if self.path == '/app/gestion-matchs-config.js':
            return self.answer('export const config = ' + json.dumps(dict(url='http://127.0.0.1:8872', key='TEST_ONLY', binding=BINDING, writesApproved=False)), mime='text/javascript')
        if self.path == '/auth/v1/user':
            return self.answer(dict(id='TEST_USER')) if self.headers.get('Authorization') else self.answer({}, 401)
        if self.path.startswith('/rest/v1/TEST_ONLY_MATCHES'):
            if self.headers.get('Authorization') != 'Bearer TEST_ALLOWED': return self.answer({}, 403)
            return self.answer(ROWS)
        if self.path == '/app/gestion-matchs.html':
            html = (ROOT / 'app/gestion-matchs.html').read_text()
            return self.answer(html.replace('<main class="wrap">', '<main class="wrap"><p class="notice">APERÇU LOCAL — données fictives, aucun appel Supabase. Compte : autorise@example.test / 123456. Refus : refuse@example.test. Écritures verrouillées.</p>'), mime='text/html; charset=utf-8')
        return super().do_GET()
    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0))) or '{}')
        if self.path == '/auth/v1/otp': return self.answer({})
        if self.path == '/auth/v1/verify':
            if body.get('token') != '123456': return self.answer({}, 403)
            return self.answer(dict(access_token='TEST_ALLOWED' if body.get('email') == 'autorise@example.test' else 'TEST_DENIED'))
        if self.path == '/rest/v1/rpc/TEST_ONLY_ACCESS': return self.answer(self.headers.get('Authorization') == 'Bearer TEST_ALLOWED')
        if self.path == '/auth/v1/logout': return self.answer({})
        return self.answer({}, 403)
    def do_PATCH(self): return self.answer({}, 403)
if __name__ == '__main__':
    print('APERÇU FICTIF : http://127.0.0.1:8872/app/gestion-matchs.html', flush=True)
    ThreadingHTTPServer(('127.0.0.1', 8872), partial(Handler, directory=str(ROOT))).serve_forever()
