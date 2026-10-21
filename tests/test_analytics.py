import unittest
from datetime import date

from analytics.category_model import default_model, evaluate, load_examples, stratified_split
from analytics.forecast import forecast_expenses
from analytics.insights import build_insights
from analytics.evaluate import forecast_backtest


def expense(month, amount):
    return {"kind": "expense", "amount_minor": amount, "category": "Groceries",
            "description": "Example", "created_at": f"{month}-15"}


class CategoryTests(unittest.TestCase):
    def test_known_description_and_unknown_vocabulary(self):
        model = default_model()
        self.assertEqual(model.predict("supermarket food shopping")["category"], "Groceries")
        self.assertIsNone(model.predict("zzqvxx")["category"])

    def test_empty_description_rejected(self):
        with self.assertRaises(ValueError):
            default_model().predict("!!!")

    def test_split_is_reproducible_and_disjoint(self):
        examples = load_examples()
        train, test = stratified_split(examples)
        self.assertEqual((train, test), stratified_split(examples))
        self.assertFalse(set(train) & set(test))
        self.assertEqual(len(train) + len(test), len(examples))
        self.assertEqual({label for _, label in train}, {label for _, label in test})

    def test_metrics_are_bounded_and_reproducible(self):
        scores = evaluate()
        self.assertEqual(scores, evaluate())
        for metric in ("accuracy", "macro_f1"):
            self.assertGreaterEqual(scores[metric], 0)
            self.assertLessEqual(scores[metric], 1)


class ForecastTests(unittest.TestCase):
    def test_requires_history(self):
        self.assertEqual(forecast_expenses([])["status"], "insufficient_data")
        self.assertEqual(forecast_expenses([expense("2025-01", 100)])["status"], "insufficient_data")

    def test_forecast_uses_past_complete_months(self):
        rows = [expense("2025-01", 100), expense("2025-02", 200),
                expense("2025-03", 300), expense("2025-04", 999999)]
        result = forecast_expenses(rows, as_of=date(2025, 4, 20))
        self.assertEqual(result["forecast_minor"], 200)
        self.assertEqual(result["forecast_month"], "2025-04")

    def test_missing_months_count_as_zero(self):
        result = forecast_expenses([expense("2025-01", 300), expense("2025-03", 600)])
        self.assertEqual(result["forecast_minor"], 300)

    def test_year_boundary(self):
        rows = [expense("2025-10", 300), expense("2025-11", 300), expense("2025-12", 300)]
        self.assertEqual(forecast_expenses(rows)["forecast_month"], "2026-01")

    def test_invalid_dates_and_income_do_not_pollute_forecast(self):
        rows = [expense("2025-13", 200), {"kind": "income", "amount_minor": 500, "created_at": "2025-01-01"}]
        self.assertEqual(forecast_expenses(rows)["status"], "insufficient_data")

    def test_category_shares_and_empty_insights(self):
        rows = [expense("2025-01", 100), expense("2025-02", 200)]
        self.assertEqual(build_insights(rows)["categories"][0]["amount_minor"], 300)
        self.assertEqual(build_insights([])["categories"], [])

    def test_backtest_has_only_future_targets(self):
        result = forecast_backtest()
        self.assertEqual(result["test_months"], 4)
        self.assertEqual(result["mean_baseline_mae_kzt"], 1250.0)


if __name__ == "__main__":
    unittest.main()
