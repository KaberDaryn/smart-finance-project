import json
import re
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal, InvalidOperation

from .merchant_categories import lookup_category, merchant_key
from .receipt_providers import ReceiptError, get_provider


MAX_IMAGE_BYTES = 5 * 1024 * 1024
CURRENCIES = ('KZT', 'RUB', 'USD', 'EUR')
MAX_RECEIPT_AGE_DAYS = 3653


def validate_image(image, mime_type):
    if not 0 < len(image) <= MAX_IMAGE_BYTES:
        raise ValueError('Receipt photo must be between 1 byte and 5 MiB')
    signatures = {
        'image/jpeg': image.startswith(b'\xff\xd8\xff'),
        'image/png': image.startswith(b'\x89PNG\r\n\x1a\n'),
        'image/webp': image.startswith(b'RIFF') and image[8:12] == b'WEBP',
    }
    if not signatures.get(mime_type, False):
        raise ValueError('Upload a JPEG, PNG, or WebP receipt photo matching its Content-Type')


def parse_response(text, today=None):
    if not isinstance(text, str) or len(text) > 65536:
        raise ReceiptError('Receipt recognition returned unreadable data. Try another photo or enter it manually.')
    text = text.strip().lstrip('\ufeff').strip()
    fenced = re.fullmatch(r'```(?:json)?\s*(.*?)\s*```', text, flags=re.DOTALL | re.IGNORECASE)
    if fenced:
        text = fenced.group(1)
    try:
        payload = json.loads(text, parse_float=Decimal, parse_int=Decimal)
    except (ValueError, RecursionError):
        raise ReceiptError('Receipt recognition returned invalid JSON. Try another photo or enter it manually.') from None
    if not isinstance(payload, dict):
        raise ReceiptError('Receipt recognition returned unreadable data. Try another photo or enter it manually.')
    merchant = payload.get('merchant')
    if not isinstance(merchant, str) or not 1 <= len(merchant.strip()) <= 200 or not merchant_key(merchant):
        merchant = None
    else:
        merchant = merchant.strip()
    today = today or datetime.now(timezone.utc).date()
    occurred_on = payload.get('date')
    try:
        if not isinstance(occurred_on, str) or not re.fullmatch(r'[0-9]{4}-[0-9]{2}-[0-9]{2}', occurred_on):
            raise ValueError
        parsed = date.fromisoformat(occurred_on)
        if not today - timedelta(days=MAX_RECEIPT_AGE_DAYS) <= parsed <= today:
            raise ValueError
    except ValueError:
        occurred_on = None
    total = payload.get('total')
    try:
        if isinstance(total, bool) or not isinstance(total, (int, float, Decimal)):
            raise ValueError
        total = Decimal(str(total))
        if not total.is_finite() or not 0 < total <= 10**10 or total != total.quantize(Decimal('0.01')):
            raise ValueError
        total = float(total)
    except (ValueError, InvalidOperation):
        total = None
    currency = payload.get('currency')
    currency = currency.strip().upper() if isinstance(currency, str) else None
    if currency not in CURRENCIES:
        currency = None
    return {'merchant': merchant, 'date': occurred_on, 'total': total, 'currency': currency}


def parse(image, mime_type, provider=None):
    validate_image(image, mime_type)
    provider = provider or get_provider()
    return parse_response(provider.extract(image, mime_type))


def with_category(db, user_id, receipt):
    category = lookup_category(db, user_id, receipt['merchant'])
    return {**receipt, 'category': category, 'category_source': 'remembered' if category is not None else None}
