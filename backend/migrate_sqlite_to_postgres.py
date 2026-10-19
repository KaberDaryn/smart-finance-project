import hashlib
import json
import os
import sqlite3
from . import store


def main():
    source_path = os.environ.get('SQLITE_PATH', 'data/finance.db')
    target_url = os.environ.get('DATABASE_URL', '')
    owner = os.environ.get('OWNER_USERNAME', '').lower()
    if not target_url.startswith(('postgres://', 'postgresql://')) or not owner:
        raise SystemExit('Set DATABASE_URL to PostgreSQL and OWNER_USERNAME to an existing target account.')
    with sqlite3.connect(f'file:{source_path}?mode=ro', uri=True) as source:
        source.row_factory = sqlite3.Row
        columns = {row['name'] for row in source.execute('PRAGMA table_info(transactions)')}
        where = ' WHERE user_id IS NULL' if 'user_id' in columns else ''
        rows = [dict(row) for row in source.execute('SELECT kind,amount_minor,category,description,created_at FROM transactions' + where + ' ORDER BY id')]
    digest = 'legacy-' + hashlib.sha256(json.dumps(rows, sort_keys=True).encode()).hexdigest()
    with store.connection(target_url) as db:
        p = store.marker(db)
        user = db.execute(f'SELECT id FROM users WHERE username={p}', (owner,)).fetchone()
        if not user:
            raise SystemExit('Create the target account in the app before importing legacy data.')
        with store.transaction(db):
            created = db.execute(f'INSERT INTO imports(user_id,content_hash) VALUES ({p},{p}) ON CONFLICT DO NOTHING RETURNING content_hash', (user['id'], digest)).fetchone()
            if not created:
                print('This legacy snapshot has already been imported; no rows added.')
                return
            for row in rows:
                store.insert(db, (row['kind'], row['amount_minor'], row['category'], row['description'], row['created_at']), user['id'])
    print(f'Imported {len(rows)} legacy rows for {owner}. The source was not modified. Target IDs are assigned anew.')


if __name__ == '__main__':
    main()
