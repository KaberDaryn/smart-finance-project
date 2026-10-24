from datetime import date, timedelta
from io import BytesIO
import json
import os
import sqlite3
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch
from urllib.error import HTTPError, URLError

from backend import auth, receipts, store
from backend.evaluate_receipts import evaluate
from backend.merchant_categories import lookup_category, merchant_key
from backend.receipt_providers import (
    GEMINI_REQUEST_TIMEOUT_SECONDS,
    GeminiProvider,
    ReceiptError,
    get_provider,
)


PHOTO = b'\xff\xd8\xff' + b'synthetic-test-image'
RECOGNIZED = {'merchant': 'Magnum', 'date': '2026-01-20', 'total': 1500.01, 'currency': 'KZT'}


class ReceiptParsingTests(unittest.TestCase):
    def test_plain_and_fenced_json_and_extra_category_is_ignored(self):
        text = json.dumps({**RECOGNIZED, 'category': 'Untrusted category'})
        for response in [text, f'```json\n{text}\n```', f'```\n{text}\n```', '\ufeff' + text]:
            with self.subTest(response=response):
                self.assertEqual(receipts.parse_response(response, date(2026, 10, 23)), RECOGNIZED)

    def test_invalid_json_is_a_clear_provider_error(self):
        for response in ['', '{broken', '[]', 'null', '42', 'explanation {"merchant": "Shop"}', '[' * 1500]:
            with self.subTest(response=response[:40]), self.assertRaises(ReceiptError):
                receipts.parse_response(response)

    def test_bad_fields_are_null_without_discarding_good_fields(self):
        today = date(2026, 10, 23)
        invalid = {
            'merchant': ['', ' ', 123, True, ['Magnum'], '1' * 201, 'ТОО №123'],
            'date': ['2026-10-24', '1999-01-01', '2026-02-30', '20261023', '20.01.2026', 1, True],
            'total': [0, -1, True, '1500.01', {}, 10**11, 1.001, float('nan'), float('inf')],
            'currency': ['GBP', 'тенге', 123, {}, True],
        }
        for field, values in invalid.items():
            for value in values:
                with self.subTest(field=field, value=value):
                    result = receipts.parse_response(json.dumps({**RECOGNIZED, field: value}), today)
                    self.assertIsNone(result[field])
                    for other in RECOGNIZED.keys() - {field}:
                        self.assertEqual(result[other], RECOGNIZED[other])

    def test_boundaries_missing_fields_and_currency_case(self):
        today = date(2026, 10, 23)
        for day in (today, today - timedelta(days=receipts.MAX_RECEIPT_AGE_DAYS)):
            self.assertEqual(receipts.parse_response(json.dumps({**RECOGNIZED, 'date': day.isoformat()}), today)['date'], day.isoformat())
        self.assertEqual(receipts.parse_response('{}'), dict.fromkeys(RECOGNIZED))
        self.assertEqual(receipts.parse_response('{"currency":" rub ","total":0.01}')['currency'], 'RUB')
        self.assertEqual(receipts.parse_response('{"total":10000000000}')['total'], 10**10)

    def test_upload_validation_runs_before_the_provider(self):
        provider = Mock()
        for photo, mime in [(b'', 'image/jpeg'), (b'not a photo', 'image/jpeg'), (PHOTO, 'text/plain'),
                            (b'x' * (receipts.MAX_IMAGE_BYTES + 1), 'image/jpeg')]:
            with self.subTest(mime=mime), self.assertRaises(ValueError):
                receipts.parse(photo, mime, provider)
        provider.extract.assert_not_called()

    def test_external_extraction_is_mocked(self):
        provider = Mock()
        provider.extract.return_value = json.dumps(RECOGNIZED)
        self.assertEqual(receipts.parse(PHOTO, 'image/jpeg', provider), RECOGNIZED)
        provider.extract.assert_called_once_with(PHOTO, 'image/jpeg')


class MerchantCategoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.db = store.connect(Path(self.temp.name) / 'receipt.db')
        self.user = auth.create_user(self.db, {'username': 'first', 'password': 'TestingPassword2026!'})['id']
        self.second = auth.create_user(self.db, {'username': 'second', 'password': 'TestingPassword2026!'})['id']

    def tearDown(self):
        self.db.close()
        self.temp.cleanup()

    def save(self, merchant, category='Groceries', **patches):
        payload = {'kind': 'expense', 'amount_minor': 150001, 'category': category, 'merchant': merchant}
        payload.update(patches)
        return store.add(self.db, payload, self.user)

    def test_normalization_handles_legal_forms_branches_quotes_and_unicode(self):
        variants = ['ТОО "Magnum Cash&Carry" №12', 'MAGNUM', ' Магнум ', 'магазин «MAGNUM» филиал № 12',
                    'LLC “Magnum Cash and Carry” 25', 'ТОО «ＭＡＧＮＵＭ» №１２']
        for value in variants:
            with self.subTest(value=value):
                self.assertEqual(merchant_key(value), 'magnum')
        self.assertEqual(merchant_key('ИП «Семейная Аптека» магазин №1'), 'семейная аптека')
        self.assertEqual(merchant_key('ООО "Coffee House" филиал 14'), 'coffee house')
        self.assertEqual(merchant_key('Chip Shop'), 'chip shop')
        self.assertNotEqual(merchant_key('Coffee House'), merchant_key('Coffee Corner'))
        self.assertEqual(merchant_key('ТОО №12'), '')

    def test_categories_are_user_scoped_and_update_on_expense_save(self):
        self.assertIsNone(lookup_category(self.db, self.user, 'MAGNUM'))
        self.save('ТОО "Magnum Cash&Carry" №12')
        self.assertEqual(lookup_category(self.db, self.user, 'MAGNUM'), 'Groceries')
        self.assertIsNone(lookup_category(self.db, self.second, 'MAGNUM'))
        self.save('MAGNUM', 'Other')
        self.assertEqual(lookup_category(self.db, self.user, 'Magnum'), 'Other')
        self.assertEqual(self.db.execute('SELECT COUNT(*) AS count FROM merchant_categories').fetchone()['count'], 1)
        self.assertEqual(len(store.transactions(self.db, self.user)), 2)

    def test_lookup_only_uses_memory_and_does_not_learn_until_save(self):
        result = receipts.with_category(self.db, self.user, RECOGNIZED)
        self.assertIsNone(result['category'])
        self.assertIsNone(result['category_source'])
        self.save('Magnum', 'Health')
        remembered = receipts.with_category(self.db, self.user, RECOGNIZED)
        self.assertEqual(remembered['category'], 'Health')
        self.assertEqual(remembered['category_source'], 'remembered')
        self.assertIsNone(receipts.with_category(self.db, self.user, {**RECOGNIZED, 'merchant': None})['category'])

    def test_rejected_expenses_and_income_do_not_change_memory(self):
        self.save('Magnum')
        for patches in [{'amount_minor': -1}, {'kind': 'income'}, {'category': ' '}]:
            with self.subTest(patches=patches), self.assertRaises(ValueError):
                self.save('Magnum', **{'category': 'Other', **patches})
        for merchant in ['', '№12', False, ['Magnum']]:
            with self.subTest(merchant=merchant), self.assertRaises(ValueError):
                self.save(merchant)
        self.assertEqual(lookup_category(self.db, self.user, 'Magnum'), 'Groceries')
        self.assertEqual(len(store.transactions(self.db, self.user)), 1)

    def test_memory_and_expense_are_atomic(self):
        self.db.execute("CREATE TRIGGER reject_memory BEFORE INSERT ON merchant_categories BEGIN SELECT RAISE(ABORT, 'test failure'); END")
        with self.assertRaises(sqlite3.IntegrityError):
            self.save('Magnum')
        self.assertEqual(store.transactions(self.db, self.user), [])
        self.assertIsNone(lookup_category(self.db, self.user, 'Magnum'))

    def test_migration_is_repeatable_and_preserves_existing_expenses(self):
        store.add(self.db, {'kind': 'expense', 'amount_minor': 100, 'category': 'Food'}, self.user)
        self.db.execute('DROP TABLE merchant_categories')
        store.initialize(self.db, False)
        store.initialize(self.db, False)
        self.assertEqual(len(store.transactions(self.db, self.user)), 1)
        self.save('Magnum')
        self.assertEqual(lookup_category(self.db, self.user, 'Magnum'), 'Groceries')


class ProviderTests(unittest.TestCase):
    @patch.dict(os.environ, {'GEMINI_API_KEY': 'test-key', 'RECEIPT_MODEL': 'gemini-3.8-flash'})
    @patch('backend.receipt_providers.urlopen')
    def test_request_sends_only_extraction_prompt_and_server_key(self, urlopen):
        response = BytesIO(json.dumps({'candidates': [{'finishReason': 'STOP', 'content': {
            'parts': [{'text': json.dumps(RECOGNIZED)}]}}]}).encode())
        urlopen.return_value = response
        self.assertEqual(json.loads(GeminiProvider().extract(PHOTO, 'image/jpeg')), RECOGNIZED)
        self.assertEqual(urlopen.call_args.kwargs['timeout'], GEMINI_REQUEST_TIMEOUT_SECONDS)
        request = urlopen.call_args.args[0]
        self.assertNotIn('test-key', request.full_url)
        self.assertEqual(request.get_header('X-goog-api-key'), 'test-key')
        payload = json.loads(request.data)
        self.assertNotIn('category', payload['system_instruction']['parts'][0]['text'])
        self.assertEqual(payload['contents'][0]['parts'][0]['inline_data']['mime_type'], 'image/jpeg')

    @patch.dict(os.environ, {'GEMINI_API_KEY': 'test-key'})
    @patch('backend.receipt_providers.urlopen')
    def test_network_quota_and_malformed_responses_are_sanitized(self, urlopen):
        for failure, status in [(TimeoutError('test-key'), 504), (URLError('test-key'), 503),
                                (HTTPError('https://example.com', 429, 'test-key', {}, None), 503),
                                (HTTPError('https://example.com', 403, 'test-key', {}, None), 503)]:
            with self.subTest(failure=failure):
                urlopen.side_effect = failure
                with self.assertRaises(ReceiptError) as caught:
                    GeminiProvider().extract(PHOTO, 'image/jpeg')
                self.assertEqual(caught.exception.status, status)
                self.assertNotIn('test-key', str(caught.exception))
        urlopen.side_effect = None
        for raw in [b'not json', b'{}', b'{"candidates": []}', b'{"candidates":[{"finishReason":"SAFETY"}]}']:
            urlopen.return_value = BytesIO(raw)
            with self.assertRaises(ReceiptError):
                GeminiProvider().extract(PHOTO, 'image/jpeg')

    def test_configuration_errors_are_clear(self):
        with patch.dict(os.environ, {'GEMINI_API_KEY': '', 'RECEIPT_PROVIDER': 'gemini'}):
            with self.assertRaises(ReceiptError) as caught:
                get_provider()
            self.assertEqual(caught.exception.status, 503)
        with patch.dict(os.environ, {'RECEIPT_PROVIDER': 'unknown'}):
            with self.assertRaises(ReceiptError):
                get_provider()


class ReceiptEvaluationTests(unittest.TestCase):
    def test_accuracy_normalizes_names_and_counts_failures_as_misses(self):
        with tempfile.TemporaryDirectory() as temp:
            (Path(temp) / 'example.jpg').write_bytes(PHOTO)
            truth = [{'file': 'example.jpg', **RECOGNIZED}, {'file': 'missing.jpg', **RECOGNIZED}]
            provider = Mock()
            provider.extract.return_value = json.dumps({**RECOGNIZED, 'merchant': 'ТОО "Magnum Cash&Carry" №12'})
            report = evaluate(temp, truth, provider)
        self.assertEqual(report['images'], 2)
        self.assertEqual(report['failures'], 1)
        for field in ('merchant', 'date', 'total'):
            self.assertEqual(report['fields'][field], {'correct': 1, 'evaluated': 2, 'accuracy': .5})
        self.assertGreaterEqual(report['response_seconds']['mean'], 0)

    def test_unknown_ground_truth_is_excluded_and_paths_cannot_escape(self):
        with tempfile.TemporaryDirectory() as temp:
            report = evaluate(temp, [{'file': 'missing.jpg', 'merchant': None}])
            self.assertIsNone(report['fields']['merchant']['accuracy'])
            with self.assertRaises(ValueError):
                evaluate(temp, [{'file': '../outside.jpg'}])
