import os
import unittest
import uuid

from backend import auth, csv_import, planning, store


@unittest.skipUnless(os.environ.get('TEST_DATABASE_URL'), 'Set TEST_DATABASE_URL to a disposable PostgreSQL database')
class PostgresTests(unittest.TestCase):
    def test_account_transactions_import_and_planning(self):
        import psycopg
        from psycopg import sql
        from psycopg.conninfo import make_conninfo
        schema = 'sf_test_' + uuid.uuid4().hex
        with psycopg.connect(os.environ['TEST_DATABASE_URL'], autocommit=True) as admin:
            admin.execute(sql.SQL('CREATE SCHEMA {}').format(sql.Identifier(schema)))
            try:
                database = make_conninfo(os.environ['TEST_DATABASE_URL'], options=f'-c search_path={schema}')
                with store.connection(database) as db:
                    user = auth.create_user(db, {'username': 'postgres_test', 'password': 'PostgresTestPassword!'})
                    store.add(db, {'kind': 'expense', 'amount_minor': 10001, 'category': 'Food'}, user['id'])
                    store.add(db, {'kind': 'income', 'amount_minor': 30000, 'category': 'Salary'}, user['id'])
                    self.assertEqual(store.summary(db, user['id'])['balance_minor'], 19999)
                    self.assertEqual(store.transactions(db), [])
                    session = auth.create_session(db, user)
                    self.assertEqual(auth.current_user(db, 'Bearer ' + session['token'])['id'], user['id'])
                    payload = {'csv': 'date,kind,amount,category\n2025-01-15,expense,3.01,Food'}
                    self.assertEqual(csv_import.import_csv(db, payload, user['id'])['imported'], 1)
                    self.assertTrue(csv_import.import_csv(db, payload, user['id'])['duplicate'])
                    planning.save_budget(db, {'month': '2025-01', 'category': '*', 'amount_minor': 100}, user['id'])
                    self.assertTrue(planning.budgets(db, user['id'], '2025-01')[0]['over_budget'])
                    goal = planning.save_goal(db, {'name': 'Trip', 'target_minor': 1000}, user['id'])
                    self.assertEqual(planning.update_goal(db, {'id': goal['id'], 'saved_minor': 1000}, user['id'])['saved_minor'], 1000)
            finally:
                admin.execute(sql.SQL('DROP SCHEMA {} CASCADE').format(sql.Identifier(schema)))
