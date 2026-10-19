import csv
from decimal import Decimal
import hashlib
import io
import re

from . import store


def parse_csv(content):
    if not isinstance(content, str) or not content.strip() or len(content.encode('utf-8')) > 120000:
        raise ValueError('CSV must contain 1 to 120000 bytes')
    reader = csv.DictReader(io.StringIO(content.lstrip('\ufeff').strip()))
    required = {'date', 'kind', 'amount', 'category'}
    if not reader.fieldnames or not required.issubset(reader.fieldnames):
        raise ValueError('CSV headers must include date,kind,amount,category; description is optional')
    values = []
    for line, row in enumerate(reader, 2):
        if len(values) >= 1000:
            raise ValueError('Import supports at most 1000 transactions')
        amount = (row.get('amount') or '').strip()
        if None in row or not re.fullmatch(r'\d{1,11}(\.\d{1,2})?', amount):
            raise ValueError(f'Invalid amount or extra fields on CSV line {line}')
        try:
            values.append(store.prepare({'date': row.get('date'), 'kind': row.get('kind'),
                'amount_minor': int(Decimal(amount) * 100), 'category': row.get('category'),
                'description': row.get('description') or ''}))
        except ValueError as error:
            raise ValueError(f'CSV line {line}: {error}') from error
    if not values:
        raise ValueError('CSV must contain at least one transaction')
    return values


def import_csv(db, payload, user_id):
    content = payload.get('csv') if isinstance(payload, dict) else None
    values = parse_csv(content)
    content_hash = hashlib.sha256(content.strip().encode('utf-8')).hexdigest()
    p = store.marker(db)
    with store.transaction(db):
        created = db.execute(f'INSERT INTO imports(user_id,content_hash) VALUES ({p},{p}) ON CONFLICT DO NOTHING RETURNING content_hash',
                             (user_id, content_hash)).fetchone()
        if created is None:
            return {'imported': 0, 'duplicate': True}
        for row in values:
            store.insert(db, row, user_id)
    return {'imported': len(values), 'duplicate': False}
