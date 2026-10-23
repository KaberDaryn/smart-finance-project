import base64
import json
import os
import re
import socket
from typing import Protocol
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


RECEIPT_PROMPT = (
    'You extract data from a photo of a cash receipt. The receipt may be in Russian, Kazakh, or English. '
    'Return only JSON, with no explanations and no markdown: '
    '{"merchant": ..., "date": ..., "total": ..., "currency": ...}. '
    'merchant: the store or venue name without the legal form (ТОО, ИП, АО, ООО, LLC) and without a branch number. '
    'date: the purchase date in YYYY-MM-DD format. '
    'total: the final amount to pay as a number with a dot as the decimal separator '
    '(not the amount before discount, not VAT, not change). '
    'currency: the currency code; if it is not stated explicitly, infer it from the receipt context. '
    'If a field is not visible or you are not sure, set it to null. Do not invent anything.'
)


class ReceiptError(Exception):
    def __init__(self, message, status=502):
        super().__init__(message)
        self.status = status


class ReceiptProvider(Protocol):
    def extract(self, image: bytes, mime_type: str) -> str:
        ...


class GeminiProvider:
    def __init__(self):
        self.key = os.environ.get('GEMINI_API_KEY', '').strip()
        self.model = os.environ.get('RECEIPT_MODEL', 'gemini-3.8-flash').strip()
        if not self.key:
            raise ReceiptError('Receipt scanning is not configured on the server. Enter the expense manually.', 503)
        if not re.fullmatch(r'[A-Za-z0-9._-]{1,100}', self.model):
            raise ReceiptError('The receipt model configuration is invalid.', 503)

    def extract(self, image: bytes, mime_type: str) -> str:
        generation = {'responseMimeType': 'application/json', 'maxOutputTokens': 4096}
        if re.match(r'gemini-[3-9]\.', self.model):
            generation['thinkingConfig'] = {'thinkingLevel': 'low'}
        body = json.dumps({
            'system_instruction': {'parts': [{'text': RECEIPT_PROMPT}]},
            'contents': [{'role': 'user', 'parts': [{
                'inline_data': {'mime_type': mime_type, 'data': base64.b64encode(image).decode('ascii')},
            }]}],
            'generationConfig': generation,
        }).encode()
        request = Request(
            f'https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent',
            data=body, headers={'Content-Type': 'application/json', 'x-goog-api-key': self.key}, method='POST',
        )
        try:
            with urlopen(request, timeout=45) as response:
                raw = response.read(1024 * 1024 + 1)
            if len(raw) > 1024 * 1024:
                raise ReceiptError('Receipt recognition returned too much data. Try another photo.')
            payload = json.loads(raw)
            candidate = payload['candidates'][0]
            if candidate.get('finishReason') not in (None, 'STOP'):
                raise ReceiptError('Receipt recognition could not read this photo. Try another photo or enter it manually.')
            parts = candidate['content']['parts']
            result = ''.join(part['text'] for part in parts if 'text' in part and not part.get('thought'))
            if not result.strip():
                raise ReceiptError('No receipt data was returned. Try another photo or enter it manually.')
            return result
        except HTTPError as error:
            if error.code == 429:
                raise ReceiptError('Receipt scanning quota is exhausted. Try later or enter the expense manually.', 503) from None
            if error.code in (401, 403, 404):
                raise ReceiptError('Receipt scanning is unavailable. Check the server key and model configuration.', 503) from None
            raise ReceiptError('The receipt service could not process this photo. Try again or enter it manually.') from None
        except (TimeoutError, socket.timeout):
            raise ReceiptError('Receipt scanning timed out. Try again or enter the expense manually.', 504) from None
        except URLError:
            raise ReceiptError('The receipt service is unreachable. Try later or enter the expense manually.', 503) from None
        except (ValueError, KeyError, IndexError, TypeError, AttributeError, RecursionError, UnicodeError):
            raise ReceiptError('The receipt service returned unreadable data. Try again or enter it manually.') from None


PROVIDERS = {'gemini': GeminiProvider}


def get_provider() -> ReceiptProvider:
    name = os.environ.get('RECEIPT_PROVIDER', 'gemini').strip().lower()
    factory = PROVIDERS.get(name)
    if factory is None:
        raise ReceiptError('The receipt provider configuration is invalid.', 503)
    return factory()
