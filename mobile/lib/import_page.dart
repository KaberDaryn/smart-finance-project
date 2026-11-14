import 'package:flutter/material.dart';
import 'api.dart';
import 'design_system.dart';

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
            const SFPageHeader(
              eyebrow: 'YOUR MONEY MOVEMENT',
              title: 'Import transactions',
              subtitle: 'Bring your transactions into one place.',
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SFColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SFColors.line),
                      ),
                      child: const SelectableText(
                        'date,kind,amount,category,description\n2025-01-15,expense,1500.00,Groceries,Food shopping',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.6,
                          color: SFColors.muted,
                        ),
                      ),
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
