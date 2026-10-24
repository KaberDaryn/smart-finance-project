import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_finance/main.dart';

http.Response jsonResponse(dynamic data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> sampleTransaction([String category = 'Groceries']) => {
  'id': 1,
  'kind': 'expense',
  'amount_minor': 150001,
  'category': category,
  'description': 'Demo purchase',
  'created_at': '2025-01-20 12:00:00',
};

MockClient mockApi({
  bool fail = false,
  bool failInsights = false,
  bool failSave = false,
  List<Map<String, dynamic>>? rows,
  List<Map<String, dynamic>>? budgetRows,
  Map<String, dynamic>? analyticsData,
  void Function(Map<String, dynamic>)? onSave,
}) {
  final items = rows ?? <Map<String, dynamic>>[];
  return MockClient((request) async {
    if (fail) return jsonResponse({'error': 'Unavailable'}, 500);
    switch (request.url.path) {
      case '/auth/login':
        return jsonResponse({'token': 'test-token'});
      case '/auth/register':
        return jsonResponse({'token': 'test-token'}, 201);
      case '/auth/logout':
        return jsonResponse({'status': 'signed_out'});
      case '/transactions/import':
        return jsonResponse({'imported': 1, 'duplicate': false});
      case '/transactions':
        if (request.method == 'POST') {
          if (failSave) return jsonResponse({'error': 'Unavailable'}, 500);
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          onSave?.call(payload);
          final saved = {...sampleTransaction(), ...payload};
          items.add(saved);
          return jsonResponse(saved, 201);
        }
        return jsonResponse(items);
      case '/budgets':
        return jsonResponse(request.method == 'POST' ? {} : budgetRows ?? []);
      case '/goals':
        return jsonResponse(
          request.method == 'POST' ? {} : [],
          request.method == 'POST' ? 201 : 200,
        );
      case '/summary':
        return jsonResponse({
          'balance_minor': -150001,
          'income_minor': 0,
          'expense_minor': 150001,
        });
      case '/analytics':
        if (failInsights) return jsonResponse({}, 500);
        return jsonResponse(
          analyticsData ??
              {
                'categories': [],
                'months': [],
                'forecast': {'status': 'insufficient_data'},
              },
        );
      case '/analytics/classify':
        return jsonResponse({'category': 'Groceries', 'confidence': 0.8});
      default:
        return jsonResponse({}, 404);
    }
  });
}

Future<void> openForm(WidgetTester tester) async {
  await tester.tap(find.text('Add transaction'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sign in opens the app and sign out returns to login', (
    tester,
  ) async {
    await tester.pumpWidget(FinanceApp(client: mockApi()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'tester');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'TestingPassword2026!',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);
    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Your finances, in one place'), findsOneWidget);
  });

  testWidgets('planning creates an overall monthly budget', (tester) async {
    await tester.pumpWidget(
      FinanceApp(initialToken: 'test-token', client: mockApi()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set a budget'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '25000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Savings goals'), findsOneWidget);
  });

  testWidgets('CSV import reports the number of imported transactions', (
    tester,
  ) async {
    await tester.pumpWidget(
      FinanceApp(initialToken: 'test-token', client: mockApi()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Import CSV'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'date,kind,amount,category\n2025-01-01,expense,10.00,Food',
    );
    final button = find.widgetWithText(FilledButton, 'Import transactions');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('1 transaction imported.'), findsOneWidget);
  });

  testWidgets('empty state gives a clear next action', (tester) async {
    await tester.pumpWidget(
      FinanceApp(initialToken: 'test-token', client: mockApi()),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No transactions yet'), findsOneWidget);
    expect(find.text('Add transaction'), findsOneWidget);
  });

  testWidgets('overview shows account totals and cash flow', (tester) async {
    await tester.pumpWidget(
      FinanceApp(
        initialToken: 'test-token',
        client: mockApi(rows: [sampleTransaction()]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('Total income'), findsOneWidget);
    expect(find.text('Total expenses'), findsOneWidget);
    expect(find.text('Cash flow'), findsOneWidget);
  });

  testWidgets('insights show live category and budget data', (tester) async {
    final currentMonth = DateTime.now().toUtc().toIso8601String().substring(
      0,
      7,
    );
    await tester.pumpWidget(
      FinanceApp(
        initialToken: 'test-token',
        client: mockApi(
          rows: [sampleTransaction()],
          budgetRows: [
            {
              'id': 1,
              'month': currentMonth,
              'category': 'Groceries',
              'amount_minor': 100000,
              'spent_minor': 85000,
              'remaining_minor': 15000,
              'over_budget': false,
            },
          ],
          analyticsData: {
            'categories': [
              {'category': 'Groceries', 'amount_minor': 85000, 'share': 1.0},
            ],
            'months': [
              {'month': currentMonth, 'expense_minor': 85000},
            ],
            'forecast': {'status': 'unavailable'},
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Expenses by category'), findsOneWidget);
    expect(find.text('Top category'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.textContaining('You have used 85%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('connection error offers retry', (tester) async {
    await tester.pumpWidget(
      FinanceApp(initialToken: 'test-token', client: mockApi(fail: true)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not load transactions'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('analytics failure leaves transactions usable', (tester) async {
    await tester.pumpWidget(
      FinanceApp(
        initialToken: 'test-token',
        client: mockApi(failInsights: true, rows: [sampleTransaction()]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.textContaining('Groceries'), findsOneWidget);
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Your transactions are still available'),
      findsOneWidget,
    );
  });

  testWidgets('form rejects empty fields and saves exact minor units', (
    tester,
  ) async {
    Map<String, dynamic>? payload;
    await tester.pumpWidget(
      FinanceApp(
        initialToken: 'test-token',
        client: mockApi(onSave: (value) => payload = value),
      ),
    );
    await tester.pumpAndSettle();
    await openForm(tester);
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a category.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '1500.01');
    await tester.enterText(find.byType(TextFormField).at(1), 'Groceries');
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();
    expect(payload?['amount_minor'], 150001);
    expect(payload?['date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    expect(find.text('Transaction saved.'), findsOneWidget);
  });

  testWidgets('failed save preserves form values', (tester) async {
    await tester.pumpWidget(
      FinanceApp(initialToken: 'test-token', client: mockApi(failSave: true)),
    );
    await tester.pumpAndSettle();
    await openForm(tester);
    await tester.enterText(find.byType(TextFormField).at(0), '75.50');
    await tester.enterText(find.byType(TextFormField).at(1), 'Transport');
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not confirm the save'), findsOneWidget);
    expect(find.text('75.50'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
  });

  testWidgets('category suggestion can be edited before saving', (
    tester,
  ) async {
    await tester.pumpWidget(
      FinanceApp(initialToken: 'test-token', client: mockApi()),
    );
    await tester.pumpAndSettle();
    await openForm(tester);
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'supermarket food shopping',
    );
    await tester.ensureVisible(find.text('Suggest category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suggest category'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      'Groceries',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Food');
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('narrow layout handles long categories and large amounts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      FinanceApp(
        initialToken: 'test-token',
        client: mockApi(
          rows: [
            sampleTransaction(
              'A very long category name with multiple words for testing wrapping',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('search filters the visible transaction list', (tester) async {
    await tester.pumpWidget(
      FinanceApp(
        initialToken: 'test-token',
        client: mockApi(rows: [sampleTransaction()]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'no-match');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.textContaining('No matching transactions'), findsOneWidget);
  });
}
