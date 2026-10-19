import http.client
import json
from http.server import ThreadingHTTPServer
from pathlib import Path
import tempfile
import threading
import unittest

from backend.server import Handler
from backend import auth, store


class QuietHandler(Handler):
    def log_message(self, *args):
        pass


class ApiTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        root = Path(self.temp.name)
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), QuietHandler)
        self.server.database = str(root / "test.db")
        self.server.webroot = root / "web"
        self.server.webroot.mkdir()
        (self.server.webroot / "index.html").write_text("<title>Smart Finance</title>", encoding="utf-8")
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        with store.connection(self.server.database) as db:
            user = auth.create_user(db, {'username': 'tester', 'password': 'TestingPassword2026!'})
            self.authorization = 'Bearer ' + auth.create_session(db, user)['token']

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()
        self.temp.cleanup()

    def request(self, method, path, body=None, headers=None):
        connection = http.client.HTTPConnection("127.0.0.1", self.server.server_port, timeout=5)
        request_headers = {'Authorization': self.authorization}
        request_headers.update(headers or {})
        connection.request(method, path, body, request_headers)
        response = connection.getresponse()
        status, data, response_headers = response.status, response.read(), dict(response.getheaders())
        connection.close()
        return status, data, response_headers

    def post(self, path, data):
        status, body, _ = self.request("POST", path, json.dumps(data).encode(), {"Content-Type": "application/json"})
        return status, json.loads(body)

    def test_transaction_roundtrip_with_date_and_summary(self):
        payload = {"kind": "expense", "amount_minor": 150001, "category": "Groceries",
                   "description": "Example purchase", "date": "2025-01-20"}
        status, saved = self.post("/transactions", payload)
        self.assertEqual(status, 201)
        self.assertTrue(saved["created_at"].startswith("2025-01-20"))
        status, body, _ = self.request("GET", "/transactions")
        self.assertEqual(json.loads(body)[0]["id"], saved["id"])
        _, body, _ = self.request("GET", "/summary")
        self.assertEqual(json.loads(body)["balance_minor"], -150001)

    def test_repeated_requests_open_independent_connections(self):
        for _ in range(4):
            self.assertEqual(self.request("GET", "/transactions")[0], 200)
            self.assertEqual(self.request("GET", "/summary")[0], 200)

    def test_invalid_request_and_future_date_are_rejected(self):
        self.assertEqual(self.request("POST", "/transactions", b"{broken")[0], 400)
        self.assertEqual(self.post("/transactions", {"kind": "expense", "amount_minor": True, "category": "Food"})[0], 400)
        self.assertEqual(self.post("/transactions", {"kind": "expense", "amount_minor": 100, "category": "Food", "date": "2999-01-01"})[0], 400)
        _, body, _ = self.request("GET", "/transactions")
        self.assertEqual(json.loads(body), [])

    def test_classifier_and_insights(self):
        status, result = self.post("/analytics/classify", {"description": "supermarket food shopping"})
        self.assertEqual(status, 503)
        self.assertIn("unavailable", result["error"].lower())
        self.assertEqual(self.post("/analytics/classify", {"description": ""})[0], 400)
        self.assertEqual(self.request("GET", "/analytics")[0], 200)

    def test_static_app_cannot_escape_web_directory(self):
        status, body, _ = self.request("GET", "/")
        self.assertEqual(status, 200)
        self.assertIn(b"Smart Finance", body)
        self.assertEqual(self.request("GET", "/%2e%2e/test.db")[0], 404)

    def test_only_local_development_origins_receive_cors_headers(self):
        _, _, headers = self.request("GET", "/health", headers={"Origin": "http://localhost:5000"})
        self.assertEqual(headers.get("Access-Control-Allow-Origin"), "http://localhost:5000")
        _, _, headers = self.request("GET", "/health", headers={"Origin": "https://example.com"})
        self.assertNotIn("Access-Control-Allow-Origin", headers)

    def test_unknown_endpoint_and_oversized_body(self):
        self.assertEqual(self.request("POST", "/missing", b"{}")[0], 404)
        self.assertEqual(self.request("POST", "/transactions", b" " * 16385)[0], 400)

    def test_private_routes_require_auth_and_logout_revokes_token(self):
        self.assertEqual(self.request('GET', '/transactions', headers={'Authorization': ''})[0], 401)
        self.assertEqual(self.post('/auth/logout', {})[0], 200)
        self.assertEqual(self.request('GET', '/summary')[0], 401)

    def test_register_login_and_duplicate_username(self):
        credentials = {'username': 'another', 'password': 'AnotherPassword2026!'}
        self.assertEqual(self.post('/auth/register', credentials)[0], 201)
        self.assertEqual(self.post('/auth/register', credentials)[0], 409)
        status, result = self.post('/auth/login', credentials)
        self.assertEqual(status, 200)
        self.assertIn('token', result)
        self.assertNotIn('password_hash', result['user'])
        self.assertEqual(self.post('/auth/login', {**credentials, 'password': 'IncorrectPassword!'})[0], 401)

    def test_users_cannot_read_each_others_transactions_or_goals(self):
        self.post('/transactions', {'kind': 'expense', 'amount_minor': 100, 'category': 'Food'})
        _, goal = self.post('/goals', {'name': 'Trip', 'target_minor': 10000})
        _, session = self.post('/auth/register', {'username': 'second', 'password': 'SecondPassword2026!'})
        self.authorization = 'Bearer ' + session['token']
        _, body, _ = self.request('GET', '/transactions')
        self.assertEqual(json.loads(body), [])
        self.assertEqual(self.post('/goals/update', {'id': goal['id'], 'saved_minor': 100})[0], 400)

    def test_budget_alerts_and_goal_progress(self):
        from datetime import datetime, timezone
        month = datetime.now(timezone.utc).strftime('%Y-%m')
        self.assertEqual(self.post('/budgets', {'month': month, 'category': '*', 'amount_minor': 10000})[0], 200)
        self.post('/transactions', {'kind': 'expense', 'amount_minor': 15000, 'category': 'Food'})
        _, body, _ = self.request('GET', '/analytics')
        data = json.loads(body)
        self.assertTrue(data['budgets'][0]['over_budget'])
        self.assertIn('above its budget', data['recommendations'][0])
        _, goal = self.post('/goals', {'name': 'Trip', 'target_minor': 10000})
        self.assertEqual(self.post('/goals/update', {'id': goal['id'], 'saved_minor': 10000})[1]['saved_minor'], 10000)
        self.assertEqual(self.post('/goals/update', {'id': goal['id'], 'saved_minor': 10001})[0], 400)

    def test_csv_import_is_atomic_and_repeatable_without_duplicates(self):
        content = 'date,kind,amount,category,description\n2025-01-01,expense,10.01,Food,Example'
        self.assertEqual(self.post('/transactions/import', {'csv': content})[1]['imported'], 1)
        self.assertTrue(self.post('/transactions/import', {'csv': content})[1]['duplicate'])
        bad_content = content + '\n2025-01-02,expense,-1,Food,Invalid'
        self.assertEqual(self.post('/transactions/import', {'csv': bad_content})[0], 400)
        _, body, _ = self.request('GET', '/transactions')
        self.assertEqual(len(json.loads(body)), 1)


if __name__ == "__main__":
    unittest.main()
