import tempfile
import unittest
from pathlib import Path

from backend import store


class StoreTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / "test.db"
        self.db = store.connect(self.path)

    def tearDown(self):
        self.db.close()
        self.temp.cleanup()

    def test_persistence_and_exact_balance(self):
        for kind, amount in [("income", 100001), ("expense", 50002)]:
            store.add(self.db, {"kind": kind, "amount_minor": amount, "category": "Test"})
        self.db.close()
        self.db = store.connect(self.path)
        self.assertEqual(len(store.transactions(self.db)), 2)
        self.assertEqual(store.summary(self.db)["balance_minor"], 49999)

    def test_invalid_transactions_are_not_saved(self):
        for patch in [{"amount_minor": True}, {"amount_minor": -1}, {"amount_minor": 1.5},
                      {"category": " "}, {"kind": "transfer"}]:
            payload = {"kind": "expense", "amount_minor": 100, "category": "Test"}
            payload.update(patch)
            with self.assertRaises(ValueError):
                store.add(self.db, payload)
        self.assertEqual(store.transactions(self.db), [])

    def test_empty_summary(self):
        self.assertEqual(store.summary(self.db)["balance_minor"], 0)

