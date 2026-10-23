import re
import unicodedata

from .store import marker


def merchant_key(merchant):
    value = unicodedata.normalize('NFKC', merchant.replace('№', ' ')).casefold().replace('ё', 'е')
    words = re.findall(r'[^\W\d_]+', value, flags=re.UNICODE)
    ignored = {'тоо', 'ип', 'ао', 'ооо', 'llc', 'филиал', 'филиала', 'филиалы',
               'магазин', 'магазина', 'магазины'}
    key = ' '.join(word for word in words if word not in ignored)
    aliases = {'магнум': 'magnum', 'magnum cash carry': 'magnum', 'magnum cash and carry': 'magnum'}
    return aliases.get(key, key)


def prepare_merchant(merchant):
    if not isinstance(merchant, str) or not 1 <= len(merchant.strip()) <= 200 or not merchant_key(merchant):
        raise ValueError('merchant must contain a store name of 1 to 200 characters')
    return merchant.strip()


def lookup_category(db, user_id, merchant):
    if user_id is None or not merchant:
        return None
    key = merchant_key(merchant)
    if not key:
        return None
    p = marker(db)
    row = db.execute(f'SELECT category FROM merchant_categories WHERE user_id={p} AND merchant_key={p}',
                     (user_id, key)).fetchone()
    return row['category'] if row else None


def remember_category(db, user_id, merchant, category):
    p = marker(db)
    db.execute(f'''INSERT INTO merchant_categories(user_id, merchant_key, category)
        VALUES ({p}, {p}, {p}) ON CONFLICT(user_id, merchant_key)
        DO UPDATE SET category=excluded.category''', (user_id, merchant_key(merchant), category))
