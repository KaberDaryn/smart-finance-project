import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:smart_finance/api.dart';
import 'package:smart_finance/main.dart';
import 'package:smart_finance/receipt_image.dart';

const recognized = {
  'merchant': 'Magnum',
  'date': '2026-01-20',
  'total': 1500.01,
  'currency': 'KZT',
  'category': null,
  'category_source': null,
};

Uint8List photo() => img.encodePng(img.Image(width: 20, height: 30));

http.Response response(dynamic body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Future<void> openForm(WidgetTester tester, FinanceApi api) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    AddPage(api: api, pickPhoto: (_) async => photo()),
              ),
            ),
            child: const Text('Open form'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open form'));
  await tester.pumpAndSettle();
}

Future<void> scan(WidgetTester tester, Completer<void> requested) async {
  await tester.tap(find.text('Scan receipt'));
  await tester.pumpAndSettle();
  expect(
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Take a photo'))
        .onPressed,
    isNull,
  );
  expect(find.textContaining('external service'), findsOneWidget);
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final dynamic action = tester
        .widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Choose from gallery'),
        )
        .onPressed;
    await action();
  });
  await tester.pumpAndSettle();
  expect(requested.isCompleted, isTrue);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'compression preserves aspect ratio, caps dimensions, and writes JPEG',
    () {
      final input = img.encodePng(img.Image(width: 1800, height: 2400));
      final output = compressReceiptPhoto(input);
      final decoded = img.decodeJpg(output)!;
      expect(decoded.height, 1500);
      expect(decoded.width, 1125);
      expect(output.take(3), [255, 216, 255]);
      expect(output.length, lessThan(5 * 1024 * 1024));
      final small = img.decodeJpg(compressReceiptPhoto(photo()))!;
      expect(small.width, 20);
      expect(small.height, 30);
      expect(
        () => compressReceiptPhoto(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
    },
  );

  testWidgets('consent is required and manual entry needs no upload', (
    tester,
  ) async {
    var requests = 0;
    final api = FinanceApi(
      MockClient((request) async {
        requests++;
        return response({});
      }),
    );
    await openForm(tester, api);
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '25.50',
    );
    await tester.tap(find.text('Scan receipt'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Choose from gallery'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Enter expense manually'));
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(find.text('25.50'), findsOneWidget);
    expect(find.text('Add transaction'), findsOneWidget);
  });

  testWidgets(
    'review requires category and saves edited fields through transactions',
    (tester) async {
      final requested = Completer<void>();
      Map<String, dynamic>? saved;
      final api = FinanceApi(
        MockClient((request) async {
          if (request.url.path == '/receipts/parse') {
            expect(request.headers['authorization'], 'Bearer test-token');
            expect(request.headers['content-type'], 'image/jpeg');
            expect(request.bodyBytes.take(3), [255, 216, 255]);
            requested.complete();
            return response(recognized);
          }
          expect(request.url.path, '/transactions');
          saved = jsonDecode(request.body) as Map<String, dynamic>;
          return response(saved, 201);
        }),
        token: 'test-token',
      );
      await openForm(tester, api);
      await scan(tester, requested);
      expect(find.text('Review receipt'), findsOneWidget);
      expect(find.text('1500.01'), findsOneWidget);
      await tapVisible(tester, find.text('Save transaction'));
      expect(saved, isNull);
      expect(find.text('Choose a category.'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Health'));
      await tester.ensureVisible(
        find.byKey(const ValueKey('transaction-amount')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('transaction-amount')),
        '1500.02',
      );
      await tapVisible(tester, find.text('Save transaction'));
      expect(saved?['amount_minor'], 150002);
      expect(saved?['category'], 'Health');
      expect(saved?['merchant'], 'Magnum');
      expect(saved?['date'], '2026-01-20');
    },
  );

  testWidgets('remembered custom category can be changed with one chip tap', (
    tester,
  ) async {
    final requested = Completer<void>();
    Map<String, dynamic>? saved;
    final api = FinanceApi(
      MockClient((request) async {
        if (request.url.path == '/receipts/parse') {
          requested.complete();
          return response({
            ...recognized,
            'category': 'Weekly shopping',
            'category_source': 'remembered',
          });
        }
        saved = jsonDecode(request.body) as Map<String, dynamic>;
        return response(saved, 201);
      }),
    );
    await openForm(tester, api);
    await scan(tester, requested);
    await tester.ensureVisible(
      find.widgetWithText(ChoiceChip, 'Weekly shopping'),
    );
    expect(
      tester
          .widget<ChoiceChip>(
            find.widgetWithText(ChoiceChip, 'Weekly shopping'),
          )
          .selected,
      isTrue,
    );
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Other'));
    await tapVisible(tester, find.text('Save transaction'));
    expect(saved?['category'], 'Other');
  });

  testWidgets('missing fields stay empty until corrected by the user', (
    tester,
  ) async {
    final requested = Completer<void>();
    Map<String, dynamic>? saved;
    final api = FinanceApi(
      MockClient((request) async {
        if (request.url.path == '/receipts/parse') {
          requested.complete();
          return response({for (final field in recognized.keys) field: null});
        }
        saved = jsonDecode(request.body) as Map<String, dynamic>;
        return response(saved, 201);
      }),
    );
    await openForm(tester, api);
    await scan(tester, requested);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('receipt-merchant')))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('receipt-date')))
          .controller!
          .text,
      isEmpty,
    );
    await tapVisible(tester, find.text('Save transaction'));
    expect(saved, isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('receipt-merchant')));
    await tester.enterText(
      find.byKey(const ValueKey('receipt-merchant')),
      'Local shop',
    );
    await tapVisible(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.text('KZT').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '25.75',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('receipt-date')));
    await tester.enterText(
      find.byKey(const ValueKey('receipt-date')),
      '2026-02-30',
    );
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Groceries'));
    await tapVisible(tester, find.text('Save transaction'));
    expect(saved, isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('receipt-date')));
    await tester.enterText(
      find.byKey(const ValueKey('receipt-date')),
      '2026-01-20',
    );
    await tapVisible(tester, find.text('Save transaction'));
    expect(saved?['merchant'], 'Local shop');
    expect(saved?['amount_minor'], 2575);
  });

  testWidgets('foreign currency requires a manually entered KZT amount', (
    tester,
  ) async {
    final requested = Completer<void>();
    Map<String, dynamic>? saved;
    final api = FinanceApi(
      MockClient((request) async {
        if (request.url.path == '/receipts/parse') {
          requested.complete();
          return response({
            ...recognized,
            'total': 100,
            'currency': 'RUB',
            'category': 'Other',
            'category_source': 'remembered',
          });
        }
        saved = jsonDecode(request.body) as Map<String, dynamic>;
        return response(saved, 201);
      }),
    );
    await openForm(tester, api);
    await scan(tester, requested);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('transaction-amount')),
          )
          .controller!
          .text,
      isEmpty,
    );
    await tapVisible(tester, find.text('Save transaction'));
    expect(saved, isNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-amount')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '750.00',
    );
    await tapVisible(tester, find.text('Save transaction'));
    expect(saved?['amount_minor'], 75000);
    expect(saved?['description'], contains('100.00 RUB'));
  });

  testWidgets('recognition errors show retry and preserve the manual form', (
    tester,
  ) async {
    final requested = Completer<void>();
    final api = FinanceApi(
      MockClient((request) async {
        requested.complete();
        return response({'error': 'Receipt scanning quota is exhausted.'}, 503);
      }),
    );
    await openForm(tester, api);
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '42.50',
    );
    await scan(tester, requested);
    expect(find.text('Receipt scanning quota is exhausted.'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    await tester.tap(find.text('Enter expense manually'));
    await tester.pumpAndSettle();
    expect(find.text('42.50'), findsOneWidget);
  });

  testWidgets('recognition timeouts show a retry message', (tester) async {
    final requested = Completer<void>();
    final api = FinanceApi(
      MockClient((request) async {
        requested.complete();
        throw TimeoutException('request timed out');
      }),
    );
    await openForm(tester, api);
    await scan(tester, requested);
    expect(
      find.text(
        'Receipt recognition took too long. Try again or enter the expense manually.',
      ),
      findsOneWidget,
    );
  });
}
