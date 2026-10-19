import re
from datetime import datetime, timezone
from . import store


def _amount(value, name, allow_zero=False):
    if type(value) is not int or not (0 if allow_zero else 1) <= value <= 10**12:
        raise ValueError(f'{name} must be an integer between {0 if allow_zero else 1} and 10^12')
    return value


def _text(value, name):
    if not isinstance(value, str) or not value.strip() or len(value) > 100:
        raise ValueError(f'{name} must contain 1 to 100 characters')
    return value.strip()


def budgets(db, user_id, month=None):
    month = month or datetime.now(timezone.utc).strftime('%Y-%m')
    if not isinstance(month, str) or not re.fullmatch(r'\d{4}-(0[1-9]|1[0-2])', month):
        raise ValueError('month must use YYYY-MM')
    p = store.marker(db)
    rows = db.execute(f'SELECT id,month,category,amount_minor FROM budgets WHERE user_id={p} AND month={p} ORDER BY category',
                      (user_id, month)).fetchall()
    expenses = [row for row in store.transactions(db, user_id)
                if row['kind'] == 'expense' and row['created_at'].startswith(month)]
    results = []
    for row in rows:
        result = dict(row)
        spent = sum(item['amount_minor'] for item in expenses if row['category'] == '*' or item['category'] == row['category'])
        result.update(spent_minor=spent, remaining_minor=row['amount_minor'] - spent,
                      over_budget=spent > row['amount_minor'])
        results.append(result)
    return results


def save_budget(db, payload, user_id):
    if not isinstance(payload, dict):
        raise ValueError('Expected a JSON object')
    month = payload.get('month')
    if not isinstance(month, str) or not re.fullmatch(r'\d{4}-(0[1-9]|1[0-2])', month):
        raise ValueError('month must use YYYY-MM')
    category = _text(payload.get('category'), 'category')
    amount = _amount(payload.get('amount_minor'), 'amount_minor')
    p = store.marker(db)
    with store.transaction(db):
        row = db.execute(f'''INSERT INTO budgets(user_id,month,category,amount_minor) VALUES ({p},{p},{p},{p})
            ON CONFLICT(user_id,month,category) DO UPDATE SET amount_minor=excluded.amount_minor
            RETURNING id,month,category,amount_minor''', (user_id, month, category, amount)).fetchone()
    return dict(row)


def goals(db, user_id):
    rows = db.execute(f'SELECT id,name,target_minor,saved_minor FROM goals WHERE user_id={store.marker(db)} ORDER BY id DESC', (user_id,))
    return [dict(row) for row in rows]


def save_goal(db, payload, user_id):
    if not isinstance(payload, dict):
        raise ValueError('Expected a JSON object')
    name = _text(payload.get('name'), 'name')
    target = _amount(payload.get('target_minor'), 'target_minor')
    saved = _amount(payload.get('saved_minor', 0), 'saved_minor', allow_zero=True)
    if saved > target:
        raise ValueError('Saved amount cannot exceed the goal target')
    p = store.marker(db)
    with store.transaction(db):
        row = db.execute(f'INSERT INTO goals(user_id,name,target_minor,saved_minor) VALUES ({p},{p},{p},{p}) RETURNING id,name,target_minor,saved_minor',
                         (user_id, name, target, saved)).fetchone()
    return dict(row)


def update_goal(db, payload, user_id):
    if not isinstance(payload, dict) or type(payload.get('id')) is not int:
        raise ValueError('id must be an integer')
    saved = _amount(payload.get('saved_minor'), 'saved_minor', allow_zero=True)
    p = store.marker(db)
    with store.transaction(db):
        row = db.execute(f'SELECT * FROM goals WHERE id={p} AND user_id={p}', (payload['id'], user_id)).fetchone()
        if row is None:
            raise ValueError('Goal not found')
        if saved > row['target_minor']:
            raise ValueError('Saved amount cannot exceed the goal target')
        row = db.execute(f'UPDATE goals SET saved_minor={p} WHERE id={p} AND user_id={p} RETURNING id,name,target_minor,saved_minor',
                         (saved, payload['id'], user_id)).fetchone()
    return dict(row)
