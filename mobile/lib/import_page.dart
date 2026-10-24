import 'package:flutter/material.dart';
import 'api.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key, required this.api});
  final FinanceApi api;
  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final csv = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    csv.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.api.post('/transactions/import', {
        'csv': csv.text,
      }, expectedStatus: 200);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['duplicate'] == true
                ? 'This CSV has already been imported.'
                : '${result['imported']} ${result['imported'] == 1 ? 'transaction' : 'transactions'} imported.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (failure) {
      if (mounted) {
        setState(
          () => error = failure is ApiFailure
              ? failure.message
              : 'Import could not be confirmed. Check the list before retrying.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Import transactions')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const Text(
              'YOUR MONEY MOVEMENT',
              style: TextStyle(
                color: Color(0xFF87928C),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import transactions',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bring your transactions into one place.',
              style: TextStyle(color: Color(0xFF87928C)),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Paste CSV data from a text file or spreadsheet. Amounts are in KZT. All rows are checked before anything is saved.',
                    ),
                    const SizedBox(height: 16),
                    const SelectableText(
                      'date,kind,amount,category,description\n2025-01-15,expense,1500.00,Groceries,Food shopping',
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: csv,
                      enabled: !busy,
                      minLines: 8,
                      maxLines: 18,
                      maxLength: 120000,
                      decoration: const InputDecoration(
                        labelText: 'CSV data',
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (error != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: busy ? null : submit,
                      child: Text(
                        busy ? 'Importing...' : 'Import transactions',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
