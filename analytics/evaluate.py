"""Reproduce demonstration metrics: python -m analytics.evaluate."""

import json
from pathlib import Path

from .category_model import evaluate
from .forecast import forecast_expenses


def forecast_backtest():
    # Synthetic monthly totals in minor units; no real participant data.
    totals = [2400000, 2550000, 2500000, 2700000, 2800000, 2650000,
              2900000, 3000000, 2850000, 3100000, 3200000, 3150000]
    rows = [{"kind": "expense", "amount_minor": amount,
             "created_at": f"2025-{month:02d}-15"} for month, amount in enumerate(totals, 1)]
    records = []
    for index in range(8, len(rows)):
        prediction = forecast_expenses(rows[:index])["forecast_minor"]
        actual = totals[index]
        records.append({"month": rows[index]["created_at"][:7],
                        "actual_minor": actual, "mean_prediction_minor": prediction,
                        "last_month_prediction_minor": totals[index - 1]})
    return {
        "data_note": "Twelve synthetic monthly totals; last four months evaluated with expanding past-only history.",
        "test_months": len(records),
        "mean_baseline_mae_kzt": round(sum(abs(row["actual_minor"] - row["mean_prediction_minor"]) for row in records) / len(records) / 100, 2),
        "last_month_baseline_mae_kzt": round(sum(abs(row["actual_minor"] - row["last_month_prediction_minor"]) for row in records) / len(records) / 100, 2),
        "predictions": records,
    }


def main():
    result = {"classification": evaluate(), "forecasting": forecast_backtest()}
    destination = Path(__file__).resolve().parents[1] / "docs" / "analytics-results.json"
    destination.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
