from collections import defaultdict
from datetime import datetime, timezone

from .forecast import forecast_expenses


def build_insights(transactions):
    categories = defaultdict(int)
    monthly = defaultdict(int)
    for row in transactions:
        if row["kind"] == "expense":
            categories[row["category"]] += row["amount_minor"]
            monthly[str(row["created_at"])[:7]] += row["amount_minor"]
    total = sum(categories.values())
    return {
        "currency": "KZT",
        "categories": [{"category": category, "amount_minor": amount,
                        "share": round(amount / total, 4) if total else 0}
                       for category, amount in sorted(categories.items(), key=lambda item: (-item[1], item[0]))],
        "months": [{"month": month, "expense_minor": amount}
                   for month, amount in sorted(monthly.items())[-12:]],
        "forecast": forecast_expenses(transactions, as_of=datetime.now(timezone.utc).date()),
    }
