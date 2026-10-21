import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'formatters.dart';
export 'formatters.dart';
import 'sign_in.dart';
import 'planning_page.dart';
import 'import_page.dart';

void main() => runApp(const FinanceApp());

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key, this.client, this.initialToken});
  final http.Client? client;
  final String? initialToken;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Smart Finance',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'FinanceRoboto',
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF255C48),
      scaffoldBackgroundColor: const Color(0xFFF7FAF7),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: SessionGate(client: client, initialToken: initialToken),
  );
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key, this.client, this.initialToken});
  final http.Client? client;
  final String? initialToken;
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final http.Client client;
  String? token;
  @override
  void initState() {
    super.initState();
    client = widget.client ?? http.Client();
    token = widget.initialToken;
  }

  @override
  void dispose() {
    if (widget.client == null) client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => token == null
      ? SignInPage(
          api: FinanceApi(client),
          onSignedIn: (value) => setState(() => token = value),
        )
      : TransactionsPage(
          client: client,
          token: token,
          onSignOut: () {
            if (mounted) setState(() => token = null);
          },
        );
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key, this.client, this.token, this.onSignOut});
  final http.Client? client;
  final String? token;
  final VoidCallback? onSignOut;
  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late final http.Client client;
  late final FinanceApi api;
  List<Map<String, dynamic>> items = [];
  Map<String, dynamic> summary = {};
  Map<String, dynamic>? insights;
  bool loading = true;
  bool insightsFailed = false;
  String? error;
  String kindFilter = 'all';
  String query = '';
  int page = 0;

  @override
  void initState() {
    super.initState();
    client = widget.client ?? http.Client();
    api = FinanceApi(
      client,
      token: widget.token,
      onUnauthorized: widget.onSignOut,
    );
    load();
  }

  @override
  void dispose() {
    if (widget.client == null) client.close();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
      insightsFailed = false;
    });
    try {
      final replies = await Future.wait([
        api.get('/transactions'),
        api.get('/summary'),
      ]);
      if (!mounted) return;
      setState(() {
        items = (replies[0] as List).cast<Map<String, dynamic>>();
        summary = replies[1] as Map<String, dynamic>;
      });
      try {
        final data = await api.get('/analytics') as Map<String, dynamic>;
        if (mounted) setState(() => insights = data);
      } catch (_) {
        if (mounted) {
          setState(() {
            insights = null;
            insightsFailed = true;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Could not load transactions. Check the server connection, then try again.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> add() async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => AddPage(api: api)));
    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction saved.')));
      await load();
    }
  }

  Future<void> importCsv() async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => ImportPage(api: api)));
    if (changed == true && mounted) await load();
  }

  Future<void> signOut() async {
    try {
      await api.post('/auth/logout', {}, expectedStatus: 200);
    } catch (_) {}
    if (mounted) widget.onSignOut?.call();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Smart Finance'),
      actions: [
        IconButton(
          onPressed: importCsv,
          tooltip: 'Import CSV',
          icon: const Icon(Icons.upload_file),
        ),
        IconButton(
          onPressed: loading ? null : load,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: signOut,
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: page,
      onDestinationSelected: (value) {
        setState(() => page = value);
        if (value != 2) load();
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Transactions',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          label: 'Insights',
        ),
        NavigationDestination(
          icon: Icon(Icons.savings_outlined),
          label: 'Planning',
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: add,
      icon: const Icon(Icons.add),
      label: const Text('Add transaction'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? _message(error!, retry: load)
            : page == 0
            ? _transactions()
            : page == 1
            ? _insights()
            : PlanningPage(api: api),
      ),
    ),
  );

  Widget _message(String message, {VoidCallback? retry}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (retry != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: retry, child: const Text('Try again')),
          ],
        ],
      ),
    ),
  );

  Widget _transactions() {
    final visible = items
        .where(
          (item) =>
              (kindFilter == 'all' || item['kind'] == kindFilter) &&
              '${item['category']} ${item['description']}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
      children: [
        Text('Overview', style: Theme.of(context).textTheme.headlineMedium),
        if (((insights?['budgets'] as List?) ?? []).any(
          (budget) => budget['over_budget'] == true,
        ))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: TextButton.icon(
              onPressed: () => setState(() => page = 2),
              icon: const Icon(Icons.warning_amber),
              label: const Text(
                'A monthly budget has been exceeded. Review Planning.',
              ),
            ),
          ),
        const SizedBox(height: 12),
        for (final entry in {
          'Balance': 'balance_minor',
          'Income': 'income_minor',
          'Expenses': 'expense_minor',
        }.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 24,
              runSpacing: 4,
              children: [
                Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  money(summary[entry.value] as int? ?? 0),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        const Divider(height: 32),
        Text('Transactions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search transactions',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in {
              'all': 'All',
              'income': 'Income',
              'expense': 'Expenses',
            }.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: kindFilter == entry.key,
                onSelected: (_) => setState(() => kindFilter = entry.key),
              ),
          ],
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'No transactions yet. Add your first income or expense.',
            ),
          )
        else if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'No matching transactions. Try another search or filter.',
            ),
          ),
        for (final item in visible) _transactionRow(item),
      ],
    );
  }

  Widget _transactionRow(Map<String, dynamic> item) {
    final expense = item['kind'] == 'expense';
    final description = item['description'] as String;
    final date = (item['created_at'] as String).split(RegExp('[T ]')).first;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 14),
            child: Icon(
              expense ? Icons.north_east : Icons.south_west,
              semanticLabel: expense ? 'Expense' : 'Income',
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['category'] as String,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${expense ? '-' : '+'}${money(item['amount_minor'] as int)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (description.isNotEmpty) Text(description),
                Text(date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insights() {
    if (insightsFailed || insights == null) {
      return _message(
        'Insights are unavailable. Your transactions are still available on the Transactions tab.',
        retry: load,
      );
    }
    final categories = (insights!['categories'] as List)
        .cast<Map<String, dynamic>>();
    final months = (insights!['months'] as List).cast<Map<String, dynamic>>();
    final forecast = insights!['forecast'] as Map<String, dynamic>;
    final peak = months.fold<int>(
      1,
      (value, month) => (month['expense_minor'] as int) > value
          ? month['expense_minor'] as int
          : value,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
      children: [
        Text(
          'Spending insights',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        Text(
          'Expenses by category',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (categories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Add an expense to see where your money goes.'),
          ),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category['category']} - ${money(category['amount_minor'] as int)}',
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (category['share'] as num).toDouble(),
                  semanticsLabel: '${category['category']} share of expenses',
                  semanticsValue:
                      '${((category['share'] as num) * 100).round()} percent',
                ),
              ],
            ),
          ),
        const Divider(height: 40),
        Text('Monthly expenses', style: Theme.of(context).textTheme.titleLarge),
        if (months.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No monthly expense data yet.'),
          ),
        for (final month in months)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${month['month']} - ${money(month['expense_minor'] as int)}',
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (month['expense_minor'] as int) / peak,
                  semanticsLabel: '${month['month']} expenses',
                  semanticsValue: money(month['expense_minor'] as int),
                ),
              ],
            ),
          ),
        const Divider(height: 40),
        Text('Expense estimate', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (forecast['status'] == 'ok') ...[
          Text(
            '${forecast['forecast_month']}: ${money(forecast['forecast_minor'] as int)}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Average of the previous three complete months. Missing months count as zero, so keep your diary complete. Actual expenses may differ.',
          ),
        ] else
          Text(forecast['status'] == 'unavailable'
            ? 'Forecasting is not available yet.'
            : 'Record expenses across at least three complete months to see an estimate.'),
        const Divider(height: 40),
        Text(
          'Spending observations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        for (final note in (insights!['recommendations'] as List?) ?? [])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(note as String),
          ),
      ],
    );
  }
}

class AddPage extends StatefulWidget {
  const AddPage({super.key, required this.api});
  final FinanceApi api;
  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  final category = TextEditingController();
  final description = TextEditingController();
  String kind = 'expense';
  DateTime date = DateTime.now().toUtc();
  bool saving = false;
  bool suggesting = false;
  String? error;
  String? suggestion;

  @override
  void dispose() {
    amount.dispose();
    category.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> suggest() async {
    if (description.text.trim().isEmpty) {
      setState(
        () => suggestion =
            'Add a description first, such as "supermarket food shopping".',
      );
      return;
    }
    setState(() {
      suggesting = true;
      suggestion = null;
    });
    try {
      final result = await widget.api.post('/analytics/classify', {
        'description': description.text.trim(),
      }, expectedStatus: 200);
      if (!mounted) return;
      setState(() {
        if (result['category'] != null) {
          category.text = result['category'] as String;
          suggestion = 'Category suggested. You can change it before saving.';
        } else {
          suggestion = 'No suggestion available. Enter a category yourself.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => suggestion =
              'Category suggestion is unavailable. You can still enter one yourself.',
        );
      }
    } finally {
      if (mounted) setState(() => suggesting = false);
    }
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.api.post('/transactions', {
        'kind': kind,
        'amount_minor': parseAmount(amount.text),
        'category': category.text.trim(),
        'description': description.text.trim(),
        'date': dateText(date),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Could not confirm the save. Check the transaction list before retrying to avoid duplicates.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add transaction')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              DropdownButtonFormField<String>(
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text('Expense')),
                  DropdownMenuItem(value: 'income', child: Text('Income')),
                ],
                onChanged: saving
                    ? null
                    : (value) => setState(() => kind = value!),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: amount,
                enabled: !saving,
                decoration: const InputDecoration(
                  labelText: 'Amount in KZT',
                  hintText: '1500.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) => parseAmount(value ?? '') == null
                    ? 'Enter a positive amount with up to two decimal places.'
                    : null,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text('Date: ${dateText(date)}'),
                onPressed: saving
                    ? null
                    : () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().toUtc(),
                        );
                        if (selected != null && mounted) {
                          setState(() => date = selected);
                        }
                      },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: category,
                enabled: !saving && !suggesting,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Groceries',
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter a category.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: description,
                enabled: !saving && !suggesting,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              if (kind == 'expense') ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: saving || suggesting ? null : suggest,
                    icon: const Icon(Icons.auto_fix_high),
                    label: Text(
                      suggesting ? 'Finding a category...' : 'Suggest category',
                    ),
                  ),
                ),
                if (suggestion != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(suggestion!),
                    ),
                  ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: saving || suggesting ? null : save,
                child: Text(saving ? 'Saving...' : 'Save transaction'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
