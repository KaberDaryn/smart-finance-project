"""Populate an empty database with clearly marked, fictional transactions."""

import os
from datetime import datetime, timezone
from pathlib import Path
from . import auth, planning, store


def demo_rows():
    today = datetime.now(timezone.utc).date()
    current = today.year * 12 + today.month - 1
    rows = []
    for offset in range(6, 0, -1):
        year, month0 = divmod(current - offset, 12)
        month = month0 + 1
        rows.append({"kind": "income", "amount_minor": 18000000,
                     "category": "Salary", "description": "Fictional demo salary",
                     "date": f"{year:04d}-{month:02d}-01"})
        for index, (category, amount) in enumerate([
            ("Housing", 7000000), ("Groceries", 2400000 + offset * 10000),
            ("Transport", 850000), ("Health", 400000), ("Entertainment", 600000),
        ], 1):
            rows.append({"kind": "expense", "amount_minor": amount,
                         "category": category, "description": "Fictional demo transaction",
                         "date": f"{year:04d}-{month:02d}-{index + 5:02d}"})
    return rows


def main():
    database = os.environ.get("DATABASE_URL", str(Path(__file__).resolve().parents[1] / "data" / "finance.db"))
    if not database.startswith(("postgres://", "postgresql://")):
        Path(database).parent.mkdir(parents=True, exist_ok=True)
    with store.connection(database) as db:
        if db.execute(f'SELECT id FROM users WHERE username={store.marker(db)}', ('demo',)).fetchone():
            print('The demo account already exists. Existing data was kept.')
            return
        user = auth.create_user(db, {'username': 'demo', 'password': 'DemoFinance2026!'})
        rows = demo_rows()
        for row in rows:
            store.add(db, row, user['id'])
        today = datetime.now(timezone.utc).date()
        store.add(db, {'kind': 'expense', 'amount_minor': 850000, 'category': 'Groceries',
            'description': 'Fictional current-month demo expense', 'date': today.isoformat()}, user['id'])
        planning.save_budget(db, {'month': today.strftime('%Y-%m'), 'category': 'Groceries', 'amount_minor': 800000}, user['id'])
        planning.save_goal(db, {'name': 'Demo emergency fund', 'target_minor': 10000000, 'saved_minor': 2500000}, user['id'])
    print(f"Added {len(rows)} fictional transactions over six complete months.")
    print('Demo account: demo / DemoFinance2026! (fictional local demonstration only).')


if __name__ == "__main__":
    main()
