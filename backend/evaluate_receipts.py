import argparse
from collections import Counter
from decimal import Decimal, InvalidOperation
import json
import math
import os
from pathlib import Path
import statistics
import time

from . import receipts
from .merchant_categories import merchant_key
from .receipt_providers import ReceiptError


def field_matches(field, expected, actual):
    if actual is None:
        return False
    if field == 'merchant':
        return isinstance(actual, str) and isinstance(expected, str) and merchant_key(expected) == merchant_key(actual)
    if field == 'total':
        try:
            return Decimal(str(expected)) == Decimal(str(actual))
        except InvalidOperation:
            return False
    return expected == actual


def evaluate(folder, ground_truth, provider=None):
    folder = Path(folder).resolve()
    if not folder.is_dir() or not isinstance(ground_truth, list) or not ground_truth:
        raise ValueError('Provide an image folder and a non-empty ground-truth JSON array')
    correct, counts = Counter(), Counter()
    durations, results = [], []
    seen = set()
    for item in ground_truth:
        if not isinstance(item, dict) or not isinstance(item.get('file'), str) or not item['file'].strip():
            raise ValueError('Each ground-truth row needs a file name')
        path = (folder / item['file']).resolve()
        if not path.is_relative_to(folder) or path in seen:
            raise ValueError('Receipt paths must be unique and stay inside the image folder')
        seen.add(path)
        expected = {field: item.get(field) for field in ('merchant', 'date', 'total')}
        for field, value in expected.items():
            if value is not None:
                counts[field] += 1
        started = time.perf_counter()
        error = None
        parsed = {}
        try:
            mime_type = {'.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png',
                         '.webp': 'image/webp'}.get(path.suffix.lower(), '')
            if path.stat().st_size > receipts.MAX_IMAGE_BYTES:
                raise ValueError('Resize the evaluation image to at most 5 MiB')
            parsed = receipts.parse(path.read_bytes(), mime_type, provider=provider)
        except (ReceiptError, ValueError, OSError) as failure:
            error = str(failure)
        duration = time.perf_counter() - started
        durations.append(duration)
        matches = {field: field_matches(field, value, parsed.get(field))
                   for field, value in expected.items() if value is not None}
        correct.update(field for field, matched in matches.items() if matched)
        results.append({'file': item['file'], 'seconds': round(duration, 4), 'matches': matches, 'error': error})
    ordered = sorted(durations)
    return {
        'provider': os.environ.get('RECEIPT_PROVIDER', 'gemini'),
        'model': os.environ.get('RECEIPT_MODEL', 'gemini-3.8-flash'),
        'images': len(results),
        'failures': sum(result['error'] is not None for result in results),
        'fields': {field: {'correct': correct[field], 'evaluated': counts[field],
                           'accuracy': round(correct[field] / counts[field], 4) if counts[field] else None}
                   for field in ('merchant', 'date', 'total')},
        'response_seconds': {'mean': round(statistics.mean(durations), 4),
                             'median': round(statistics.median(durations), 4),
                             'p95': round(ordered[math.ceil(len(ordered) * .95) - 1], 4)},
        'results': results,
    }


def main():
    parser = argparse.ArgumentParser(description='Evaluate receipt fields and response time against labelled images.')
    parser.add_argument('folder', type=Path)
    parser.add_argument('ground_truth', type=Path)
    parser.add_argument('--output', type=Path, default=Path('data/receipt-evaluation.json'))
    args = parser.parse_args()
    try:
        truth = json.loads(args.ground_truth.read_text(encoding='utf-8-sig'))
        report = evaluate(args.folder, truth)
    except (ValueError, OSError) as error:
        parser.error(str(error))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: value for key, value in report.items() if key != 'results'}, indent=2))
    print(f'Report written to {args.output}')


if __name__ == '__main__':
    main()
