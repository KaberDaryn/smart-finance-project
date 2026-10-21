import unittest
from unittest.mock import patch

from analytics.category_model import default_model
from analytics.insights import build_insights as analytics_insights
from backend import analytics_bridge
from backend.demo import demo_rows


class TeamIntegrationTests(unittest.TestCase):
    def test_application_uses_the_team_classifier(self):
        description = "supermarket food shopping"
        self.assertEqual(analytics_bridge.classify_description(description),
                         default_model().predict(description))

    def test_demo_history_produces_forecast_through_application_bridge(self):
        rows = [{**row, "created_at": row["date"]} for row in demo_rows()]
        result = analytics_bridge.build_insights(rows)
        self.assertEqual(result, analytics_insights(rows))
        self.assertEqual(result["forecast"]["status"], "ok")
        self.assertGreater(result["forecast"]["forecast_minor"], 0)
        self.assertTrue(result["categories"])

    def test_missing_analytics_keeps_recorded_totals_available(self):
        rows = [{"kind": "expense", "amount_minor": 150001,
                 "category": "Groceries", "created_at": "2025-01-20"}]
        with patch.object(analytics_bridge, "_optional_module", return_value=None):
            result = analytics_bridge.build_insights(rows)
            self.assertEqual(result["categories"][0]["amount_minor"], 150001)
            self.assertEqual(result["forecast"]["status"], "unavailable")
            with self.assertRaises(analytics_bridge.AnalyticsUnavailable):
                analytics_bridge.classify_description("supermarket")


if __name__ == "__main__":
    unittest.main()
