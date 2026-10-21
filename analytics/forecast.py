"""A transparent mean-of-last-three-months expense forecasting baseline."""

from collections import defaultdict
from datetime import date


def _month_index(year, month):
    return year * 12 + month - 1


def _month_name(index):
    year, month0 = divmod(index, 12)
    return f"{year:04d}-{month0 + 1:02d}"


def forecast_expenses(transactions, minimum_months=3, as_of=None):
    monthly = defaultdict(int)
    for transaction in transactions:
        if transaction.get("kind") != "expense":
            continue
        created_at = str(transaction.get("created_at", ""))
        try:
            parsed_date = date.fromisoformat(created_at[:10])
            year, month = parsed_date.year, parsed_date.month
            amount = transaction["amount_minor"]
            if type(amount) is not int or amount <= 0:
                continue
        except (ValueError, KeyError, TypeError):
            continue
        index = _month_index(year, month)
        if as_of is None or index < _month_index(as_of.year, as_of.month):
            monthly[index] += amount

    if not monthly:
        return {"status": "insufficient_data", "required_months": minimum_months,
                "observed_months": 0, "message": "No dated expense transactions are available."}

    last = max(monthly) if as_of is None else _month_index(as_of.year, as_of.month) - 1
    first = max(min(monthly), last - 11)
    history = [monthly.get(index, 0) for index in range(first, last + 1)]
    if len(history) < minimum_months:
        return {"status": "insufficient_data", "required_months": minimum_months,
                "observed_months": len(history),
                "message": f"At least {minimum_months} months of expense history are needed."}

    window = history[-3:]
    forecast = round(sum(window) / len(window))
    return {
        "status": "ok",
        "method": "arithmetic mean of the latest three calendar months",
        "history_months": [_month_name(index) for index in range(last - 2, last + 1)],
        "forecast_month": _month_name(last + 1),
        "forecast_minor": forecast,
        "currency": "KZT",
        "data_note": "A simple baseline, not financial advice or a validated prediction.",
        "assumption": "Unrecorded months after the first expense are counted as zero; keep a complete diary.",
    }
