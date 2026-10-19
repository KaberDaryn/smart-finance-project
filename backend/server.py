import json
import mimetypes
import os
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Lock
from urllib.parse import parse_qs, unquote, urlsplit

from . import auth, csv_import, planning, store
from .analytics_bridge import AnalyticsUnavailable, build_insights, classify_description

_attempt_lock = Lock()
_attempts = {}


class Handler(BaseHTTPRequestHandler):
    def setup(self):
        super().setup()
        self.connection.settimeout(15)

    def end_headers(self):
        origin = self.headers.get('Origin', '')
        parsed = urlsplit(origin)
        if parsed.scheme == 'http' and parsed.hostname in ('localhost', '127.0.0.1'):
            self.send_header('Access-Control-Allow-Origin', origin)
            self.send_header('Vary', 'Origin')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('X-Frame-Options', 'DENY')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Content-Length', '0')
        self.end_headers()

    def respond(self, status, payload):
        body = json.dumps(payload, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlsplit(self.path).path
        if path == '/health':
            self.respond(200, {'status': 'ok'})
            return
        if path not in ('/transactions', '/summary', '/analytics', '/budgets', '/goals', '/auth/me'):
            self.serve_web(path)
            return
        try:
            with store.connection(self.server.database) as db:
                user = auth.current_user(db, self.headers.get('Authorization', ''))
                if user is None:
                    self.respond(401, {'error': 'Please sign in again'})
                    return
                user_id = user['id']
                if path == '/auth/me':
                    result = user
                elif path == '/summary':
                    result = store.summary(db, user_id)
                elif path == '/budgets':
                    month = parse_qs(urlsplit(self.path).query).get('month', [None])[0]
                    result = planning.budgets(db, user_id, month)
                elif path == '/goals':
                    result = planning.goals(db, user_id)
                else:
                    rows = store.transactions(db, user_id)
                    result = build_insights(rows) if path == '/analytics' else rows
                    if path == '/analytics':
                        result['budgets'] = planning.budgets(db, user_id)
                        result['recommendations'] = self.recommendations(result)
            self.respond(200, result)
        except ValueError as error:
            self.respond(400, {'error': str(error)})
        except Exception:
            self.log_error('Data request failed')
            self.respond(500, {'error': 'Data request failed'})

    @staticmethod
    def recommendations(insights):
        notes = []
        for budget in insights['budgets']:
            if budget['over_budget']:
                category = 'All expenses' if budget['category'] == '*' else budget['category']
                notes.append(f"{category} is above its budget for {budget['month']}. Review this category in Planning.")
        if insights['categories']:
            largest = insights['categories'][0]
            notes.append(f"{largest['category']} accounts for {largest['share']:.0%} of recorded expenses.")
        if not notes:
            notes.append('Add expenses and a monthly budget to get spending observations.')
        return notes

    def auth_rate_limited(self):
        now = time.monotonic()
        address = self.client_address[0]
        with _attempt_lock:
            recent = [stamp for stamp in _attempts.get(address, []) if stamp > now - 60]
            if len(recent) >= 30:
                _attempts[address] = recent
                return True
            _attempts[address] = recent + [now]
            return False

    def do_POST(self):
        path = urlsplit(self.path).path
        routes = ('/transactions', '/transactions/import', '/analytics/classify', '/budgets', '/goals',
                  '/goals/update', '/auth/login', '/auth/register', '/auth/logout')
        if path not in routes:
            self.respond(404, {'error': 'Not found'})
            return
        if path in ('/auth/login', '/auth/register') and self.auth_rate_limited():
            self.respond(429, {'error': 'Too many sign-in attempts. Try again in a minute.'})
            return
        try:
            length = int(self.headers.get('Content-Length', '0'))
            maximum = 131072 if path == '/transactions/import' else 16384
            if not 0 < length <= maximum:
                raise ValueError(f'Request size must be 1 to {maximum} bytes')
            payload = json.loads(self.rfile.read(length).decode('utf-8'))
            with store.connection(self.server.database) as db:
                if path in ('/auth/register', '/auth/login'):
                    user = auth.create_user(db, payload) if path == '/auth/register' else auth.login(db, payload)
                    if user is None:
                        self.respond(401, {'error': 'Incorrect username or password'})
                        return
                    result = auth.create_session(db, user)
                    status = 201 if path == '/auth/register' else 200
                else:
                    authorization = self.headers.get('Authorization', '')
                    user = auth.current_user(db, authorization)
                    if user is None:
                        self.respond(401, {'error': 'Please sign in again'})
                        return
                    user_id = user['id']
                    status = 200
                    if path == '/auth/logout':
                        auth.logout(db, authorization)
                        result = {'status': 'signed_out'}
                    elif path == '/analytics/classify':
                        description = payload.get('description') if isinstance(payload, dict) else None
                        if not isinstance(description, str) or not 1 <= len(description.strip()) <= 1000:
                            raise ValueError('description must contain 1 to 1000 characters')
                        result = classify_description(description)
                    elif path == '/transactions/import':
                        result = csv_import.import_csv(db, payload, user_id)
                    elif path == '/budgets':
                        result = planning.save_budget(db, payload, user_id)
                    elif path == '/goals':
                        result = planning.save_goal(db, payload, user_id)
                        status = 201
                    elif path == '/goals/update':
                        result = planning.update_goal(db, payload, user_id)
                    else:
                        result = store.add(db, payload, user_id)
                        status = 201
            self.respond(status, result)
        except AnalyticsUnavailable as error:
            self.respond(503, {'error': str(error)})
        except auth.UserExists as error:
            self.respond(409, {'error': str(error)})
        except (ValueError, UnicodeError) as error:
            self.respond(400, {'error': str(error)})
        except Exception:
            self.log_error('Data request failed')
            self.respond(500, {'error': 'Data request failed'})
            return

    def serve_web(self, path):
        root = Path(getattr(self.server, 'webroot', Path(__file__).resolve().parents[1] / 'web')).resolve()
        candidate = (root / unquote(path).lstrip('/')).resolve()
        if not candidate.is_relative_to(root):
            self.respond(404, {'error': 'Not found'})
            return
        if candidate.is_dir():
            candidate = candidate / 'index.html'
        if not candidate.is_file():
            self.respond(404, {'error': 'Not found'})
            return
        body = candidate.read_bytes()
        self.send_response(200)
        self.send_header('Content-Type', mimetypes.guess_type(candidate.name)[0] or 'application/octet-stream')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-cache')
        self.end_headers()
        self.wfile.write(body)


def main():
    data = Path(__file__).resolve().parents[1] / 'data'
    data.mkdir(exist_ok=True)
    host = os.environ.get('HOST', '127.0.0.1')
    port = int(os.environ.get('PORT', '8000'))
    database = os.environ.get('DATABASE_URL', str(data / 'finance.db'))
    with store.connection(database):
        pass
    with ThreadingHTTPServer((host, port), Handler) as server:
        server.database = database
        print(f'Smart Finance: http://{host}:{port}', flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == '__main__':
    main()
