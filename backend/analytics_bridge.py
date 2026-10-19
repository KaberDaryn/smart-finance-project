"""Application-side contracts for the optional analytics module."""
from collections import defaultdict
from importlib import import_module


class AnalyticsUnavailable(Exception):
    pass


def _optional_module(name):
    try:
        return import_module(name)
    except ModuleNotFoundError as error:
        if error.name not in ('analytics', name):
            raise
        return None


def classify_description(description):
    module = _optional_module('analytics.category_model')
    if module is None:
        raise AnalyticsUnavailable('Category suggestions are currently unavailable. Enter a category manually.')
    return module.default_model().predict(description)


def build_insights(transactions):
    module = _optional_module('analytics.insights')
    if module is not None:
        return module.build_insights(transactions)
    categories = defaultdict(int)
    months = defaultdict(int)
    for row in transactions:
        if row['kind'] == 'expense':
            categories[row['category']] += row['amount_minor']
            months[row['created_at'][:7]] += row['amount_minor']
    total = sum(categories.values())
    return {
        'currency': 'KZT',
        'categories': [{'category': name, 'amount_minor': amount, 'share': round(amount / total, 4)}
                       for name, amount in sorted(categories.items(), key=lambda item: (-item[1], item[0]))],
        'months': [{'month': month, 'expense_minor': amount} for month, amount in sorted(months.items())[-12:]],
        'forecast': {'status': 'unavailable', 'message': 'The forecasting module is not connected.'},
    }
