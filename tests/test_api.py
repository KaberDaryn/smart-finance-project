import http.client
import json
from http.server import ThreadingHTTPServer
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch

from backend.server import Handler
from backend import auth, store
from backend.receipt_providers import ReceiptError


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
        self.assertEqual(status, 200)
        self.assertEqual(result["category"], "Groceries")
        self.assertEqual(self.post("/analytics/classify", {"description": ""})[0], 400)
        self.assertEqual(self.request("GET", "/analytics")[0], 200)

    def test_demo_history_forecast_through_authenticated_api(self):
        from backend.demo import demo_rows
        for row in demo_rows():
            self.assertEqual(self.post('/transactions', row)[0], 201)
        status, body, _ = self.request('GET', '/analytics')
        self.assertEqual(status, 200)
        result = json.loads(body)
        self.assertEqual(result['forecast']['status'], 'ok')
        self.assertGreater(result['forecast']['forecast_minor'], 0)
        self.assertEqual(result['currency'], 'KZT')
        self.assertGreater(len(result['months']), 2)
        self.assertTrue(result['categories'])
        self.assertIn('recommendations', result)

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

    @patch('backend.receipts.get_provider')
    def test_receipt_review_save_remembers_category_for_current_user(self, get_provider):
        photo = b'\xff\xd8\xffsynthetic-test-image'
        recognized = {'merchant': 'ТОО "Magnum Cash&Carry" №12', 'date': '2026-01-20',
                      'total': 1500.01, 'currency': 'KZT', 'category': 'Do not use this category'}
        get_provider.return_value.extract.return_value = json.dumps(recognized)

        def parse():
            status, body, _ = self.request('POST', '/receipts/parse', photo, {'Content-Type': 'image/jpeg'})
            self.assertEqual(status, 200)
            return json.loads(body)

        result = parse()
        self.assertEqual(set(result), {'merchant', 'date', 'total', 'currency', 'category', 'category_source'})
        self.assertIsNone(result['category'])
        _, body, _ = self.request('GET', '/transactions')
        self.assertEqual(json.loads(body), [])
        self.assertEqual(self.post('/transactions', {'kind': 'expense', 'amount_minor': 150001,
                         'merchant': result['merchant'], 'category': 'Groceries', 'date': result['date']})[0], 201)
        self.assertEqual(parse()['category'], 'Groceries')
        self.assertEqual(parse()['category_source'], 'remembered')
        self.post('/transactions', {'kind': 'expense', 'amount_minor': 100, 'merchant': 'MAGNUM', 'category': 'Other'})
        self.assertEqual(parse()['category'], 'Other')
        _, session = self.post('/auth/register', {'username': 'receipt_second', 'password': 'SecondPassword2026!'})
        self.authorization = 'Bearer ' + session['token']
        self.assertIsNone(parse()['category'])

    @patch('backend.receipts.get_provider')
    def test_receipt_auth_and_bad_uploads_do_not_call_provider(self, get_provider):
        photo = b'\xff\xd8\xffsynthetic-test-image'
        self.assertEqual(self.request('POST', '/receipts/parse', photo,
                         {'Content-Type': 'image/jpeg', 'Authorization': ''})[0], 401)
        for content, headers in [(photo, {'Content-Type': 'application/json'}),
                                 (b'not an image', {'Content-Type': 'image/jpeg'}),
                                 (photo, {'Content-Type': 'image/jpeg', 'Content-Length': str(6 * 1024 * 1024)})]:
            with self.subTest(headers=headers):
                self.assertEqual(self.request('POST', '/receipts/parse', content, headers)[0], 400)
        get_provider.assert_not_called()

    @patch('backend.receipts.get_provider')
    def test_receipt_invalid_json_and_quota_errors_do_not_crash_server(self, get_provider):
        provider = get_provider.return_value
        provider.extract.return_value = '{broken'
        photo = b'\xff\xd8\xffsynthetic-test-image'
        status, body, _ = self.request('POST', '/receipts/parse', photo, {'Content-Type': 'image/jpeg'})
        self.assertEqual(status, 502)
        self.assertIn('invalid JSON', json.loads(body)['error'])
        provider.extract.side_effect = ReceiptError('Receipt scanning quota is exhausted.', 503)
        self.assertEqual(self.request('POST', '/receipts/parse', photo, {'Content-Type': 'image/jpeg'})[0], 503)
        self.assertEqual(self.request('GET', '/summary')[0], 200)


if __name__ == "__main__":
    unittest.main()
