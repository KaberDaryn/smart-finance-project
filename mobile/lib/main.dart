import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'formatters.dart';
export 'formatters.dart';
import 'sign_in.dart';
import 'planning_page.dart';
import 'import_page.dart';
import 'expense_categories.dart';
import 'receipt_scan_page.dart';

const _categoryColors = [
  Color(0xFF3D8060),
  Color(0xFF7EA7D5),
  Color(0xFF9E8BD3),
  Color(0xFFE6AE75),
  Color(0xFFB7C1BB),
];

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
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7FAF7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE9EEEA)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFF0F4F1),
        indicatorColor: const Color(0xFFD5EDE0),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
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
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> goals = [];
  Map<String, dynamic> summary = {};
  Map<String, dynamic>? insights;
  bool loading = true;
  bool insightsFailed = false;
  String? error;
  String kindFilter = 'all';
  String query = '';
  String cashFlowRange = '6m';
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
        api.get('/budgets'),
        api.get('/goals'),
      ]);
      if (!mounted) return;
      setState(() {
        items = (replies[0] as List).cast<Map<String, dynamic>>();
        summary = replies[1] as Map<String, dynamic>;
        budgets = (replies[2] as List).cast<Map<String, dynamic>>();
        goals = (replies[3] as List).cast<Map<String, dynamic>>();
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

  Future<void> add({bool scanReceipt = false}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddPage(
          api: api,
          startReceiptScanner: scanReceipt,
          categories: {
            ...expenseCategories,
            ...items
                .where((item) => item['kind'] == 'expense')
                .map((item) => item['category'] as String),
          }.toList(),
        ),
      ),
    );
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
        if (value != 3) load();
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Overview',
        ),
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
    floatingActionButton: page == 0
        ? null
        : FloatingActionButton.extended(
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
            ? _overview()
            : page == 1
            ? _transactions()
            : page == 2
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

  Widget _overview() {
    final recent = items.take(5).toList();
    final monthTotals = <String, Map<String, int>>{};
    for (final item in items) {
      final date = item['created_at'] as String? ?? '';
      if (date.length < 7) continue;
      final month = date.substring(0, 7);
      final totals = monthTotals.putIfAbsent(
        month,
        () => {'income': 0, 'expense': 0},
      );
      final kind = item['kind'] == 'income' ? 'income' : 'expense';
      totals[kind] = totals[kind]! + (item['amount_minor'] as int? ?? 0);
    }
    final months = monthTotals.keys.toList()..sort();
    final now = DateTime.now().toUtc();
    final filteredMonths = months.where((month) {
      if (cashFlowRange == 'year') return month.startsWith('${now.year}-');
      final count = cashFlowRange == '3m' ? 3 : 6;
      final currentIndex = now.year * 12 + now.month - 1;
      final parts = month.split('-');
      final index = int.parse(parts[0]) * 12 + int.parse(parts[1]) - 1;
      return index >= currentIndex - count + 1 && index <= currentIndex;
    }).toList();
    final chartMonths = filteredMonths;
    final peak = chartMonths.fold<int>(0, (highest, month) {
      final totals = monthTotals[month]!;
      final monthlyPeak = totals['income']! > totals['expense']!
          ? totals['income']!
          : totals['expense']!;
      return monthlyPeak > highest ? monthlyPeak : highest;
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 650;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR FINANCIAL SNAPSHOT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF87928C),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Good evening, Aisultan ✳',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1D2924),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Here's what's happening with your money.",
              style: TextStyle(color: Color(0xFF87928C)),
            ),
          ],
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: heading),
                  FilledButton.icon(
                    onPressed: add,
                    icon: const Icon(Icons.add),
                    label: const Text('Add transaction'),
                  ),
                ],
              )
            else ...[
              heading,
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: add,
                  icon: const Icon(Icons.add),
                  label: const Text('Add transaction'),
                ),
              ),
            ],
            if (items.isEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'No transactions yet. Add your first income or expense.',
                style: TextStyle(color: Color(0xFF87928C)),
              ),
            ],
            const SizedBox(height: 20),
            if (wide)
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      'Total balance',
                      summary['balance_minor'] as int? ?? 0,
                      Icons.north_east,
                      dark: true,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _summaryCard(
                      'Total income',
                      summary['income_minor'] as int? ?? 0,
                      Icons.south_west,
                      accent: const Color(0xFFE7F4E9),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _summaryCard(
                      'Total expenses',
                      summary['expense_minor'] as int? ?? 0,
                      Icons.north_east,
                      accent: const Color(0xFFFBF0E6),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _summaryCard(
                      'Total balance',
                      summary['balance_minor'] as int? ?? 0,
                      Icons.north_east,
                      dark: true,
                      width: 250,
                    ),
                    const SizedBox(width: 12),
                    _summaryCard(
                      'Total income',
                      summary['income_minor'] as int? ?? 0,
                      Icons.south_west,
                      accent: const Color(0xFFE7F4E9),
                      width: 250,
                    ),
                    const SizedBox(width: 12),
                    _summaryCard(
                      'Total expenses',
                      summary['expense_minor'] as int? ?? 0,
                      Icons.north_east,
                      accent: const Color(0xFFFBF0E6),
                      width: 250,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Cash flow',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: cashFlowRange,
                            isDense: true,
                            items: const [
                              DropdownMenuItem(
                                value: '6m',
                                child: Text('Last 6 months'),
                              ),
                              DropdownMenuItem(
                                value: '3m',
                                child: Text('Last 3 months'),
                              ),
                              DropdownMenuItem(
                                value: 'year',
                                child: Text('This year'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => cashFlowRange = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Income vs. expenses over time',
                      style: TextStyle(color: Color(0xFF87928C)),
                    ),
                    const SizedBox(height: 20),
                    if (chartMonths.isEmpty)
                      const SizedBox(
                        height: 110,
                        child: Center(
                          child: Text(
                            'Add transactions to see your cash flow.',
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 150,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final month in chartMonths)
                              Expanded(
                                child: _cashFlowMonth(
                                  month,
                                  monthTotals[month]!,
                                  peak,
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 18,
                      children: [
                        _ChartLegend(color: Color(0xFF3D8060), label: 'Income'),
                        _ChartLegend(
                          color: Color(0xFFBCD8C5),
                          label: 'Expenses',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _overviewBudgets()),
                  const SizedBox(width: 14),
                  Expanded(child: _overviewGoals()),
                ],
              )
            else ...[
              _overviewBudgets(),
              const SizedBox(height: 14),
              _overviewGoals(),
            ],
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent transactions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => page = 1),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    if (recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No transactions yet. Add your first income or expense.',
                        ),
                      )
                    else
                      for (final item in recent) _recentTransaction(item),
                  ],
                ),
              ),
            ),
            if (((insights?['budgets'] as List?) ?? []).any(
              (budget) => budget['over_budget'] == true,
            ))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton.icon(
                  onPressed: () => setState(() => page = 3),
                  icon: const Icon(Icons.warning_amber),
                  label: const Text(
                    'A monthly budget has been exceeded. Review Planning.',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    String title,
    int amount,
    IconData icon, {
    bool dark = false,
    Color accent = const Color(0xFFF1F5F2),
    double? width,
  }) {
    final foreground = dark ? Colors.white : const Color(0xFF202F26);
    return SizedBox(
      width: width,
      height: 150,
      child: Card(
        color: dark ? const Color(0xFF245B48) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: dark
                            ? const Color(0xFFD2E2D8)
                            : const Color(0xFF87928C),
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: dark ? const Color(0xFF3B725F) : accent,
                    child: Icon(
                      icon,
                      size: 16,
                      color: dark ? Colors.white : const Color(0xFF3D8060),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _dashboardMoney(amount),
                  style: TextStyle(
                    color: foreground,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All time',
                style: TextStyle(
                  color: dark
                      ? const Color(0xFFD2E2D8)
                      : const Color(0xFF9AA49D),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewBudgets() {
    final month = DateTime.now().toUtc().toIso8601String().substring(0, 7);
    final monthBudgets = budgets
        .where((budget) => budget['month'] == month)
        .toList();
    final total = monthBudgets.fold<int>(
      0,
      (sum, budget) => sum + (budget['amount_minor'] as int? ?? 0),
    );
    final spent = monthBudgets.fold<int>(
      0,
      (sum, budget) => sum + (budget['spent_minor'] as int? ?? 0),
    );
    final overall = monthBudgets.where((budget) => budget['category'] == '*');
    final Iterable<Map<String, dynamic>> displayed = overall.isNotEmpty
        ? [overall.first]
        : monthBudgets.take(3);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly budget',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Keep your spending on track',
                        style: TextStyle(
                          color: Color(0xFF87928C),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'View all budgets',
                  onPressed: () => setState(() => page = 3),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
            if (monthBudgets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No budget set for this month.',
                  style: TextStyle(color: Color(0xFF87928C)),
                ),
              )
            else ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spent this month',
                          style: TextStyle(
                            color: Color(0xFF87928C),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dashboardMoney(spent),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  if (total > 0)
                    Text(
                      '${(spent * 100 / total).round()}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: spent > total
                            ? const Color(0xFFB54737)
                            : const Color(0xFF3D8060),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: (spent / total).clamp(0, 1).toDouble(),
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE9F0EA),
                    color: spent > total
                        ? const Color(0xFFC96A56)
                        : const Color(0xFF3D8060),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              for (final budget in displayed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          budget['category'] == '*'
                              ? 'All expenses'
                              : budget['category'] as String,
                        ),
                      ),
                      Text(
                        '${_dashboardMoney(budget['spent_minor'] as int? ?? 0)} / ${_dashboardMoney(budget['amount_minor'] as int? ?? 0)}',
                        style: const TextStyle(
                          color: Color(0xFF647269),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openPlanningForm(false),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewGoals() {
    final activeGoals = goals
        .where(
          (goal) =>
              (goal['saved_minor'] as int? ?? 0) <
              (goal['target_minor'] as int? ?? 0),
        )
        .toList();
    final saved = goals.fold<int>(
      0,
      (sum, goal) => sum + (goal['saved_minor'] as int? ?? 0),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Savings goals',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Small steps, big plans',
                        style: TextStyle(
                          color: Color(0xFF87928C),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'View savings goals',
                  onPressed: () => setState(() => page = 3),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
            if (goals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Add a savings goal to keep your plans in sight.',
                  style: TextStyle(color: Color(0xFF87928C)),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  '${_dashboardMoney(saved)} saved across ${activeGoals.length} active ${activeGoals.length == 1 ? 'goal' : 'goals'}',
                  style: const TextStyle(
                    color: Color(0xFF647269),
                    fontSize: 12,
                  ),
                ),
              ),
              for (final goal in goals.take(2)) _overviewGoalRow(goal),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openPlanningForm(true),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add savings goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewGoalRow(Map<String, dynamic> goal) {
    final target = goal['target_minor'] as int? ?? 0;
    final current = goal['saved_minor'] as int? ?? 0;
    final progress = target == 0 ? 0.0 : (current / target).clamp(0, 1);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: () => _updateGoal(goal),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal['name'] as String? ?? 'Savings goal',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Color(0xFF3D8060),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_dashboardMoney(current)} saved · ${_dashboardMoney(target - current)} to go',
                style: const TextStyle(color: Color(0xFF87928C), fontSize: 12),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress.toDouble(),
                  minHeight: 7,
                  backgroundColor: const Color(0xFFE9F0EA),
                  color: const Color(0xFF3D8060),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPlanningForm(bool goal) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlanningForm(api: api, goal: goal),
      ),
    );
    if (saved == true && mounted) await load();
  }

  Future<void> _updateGoal(Map<String, dynamic> goal) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GoalProgressForm(api: api, goal: goal),
      ),
    );
    if (saved == true && mounted) await load();
  }

  Widget _cashFlowMonth(String month, Map<String, int> totals, int peak) {
    final ratio = peak == 0 ? 0.0 : 100 / peak;
    final monthName = DateTime.tryParse('$month-01');
    final label = monthName == null
        ? month
        : const [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ][monthName.month - 1];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _chartBar(totals['income']! * ratio, const Color(0xFF3D8060)),
                const SizedBox(width: 4),
                _chartBar(totals['expense']! * ratio, const Color(0xFFBCD8C5)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF87928C)),
          ),
        ],
      ),
    );
  }

  Widget _chartBar(double height, Color color) => Container(
    width: 9,
    height: height.clamp(2, 100).toDouble(),
    decoration: BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
    ),
  );

  Widget _recentTransaction(Map<String, dynamic> item) {
    final income = item['kind'] == 'income';
    final description = item['description'] as String? ?? '';
    final date = (item['created_at'] as String? ?? '')
        .split(RegExp('[T ]'))
        .first;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: income
            ? const Color(0xFFE7F4E9)
            : const Color(0xFFFBF0E6),
        child: Icon(
          income ? Icons.south_west : Icons.north_east,
          color: income ? const Color(0xFF3D8060) : const Color(0xFFC78545),
          size: 18,
        ),
      ),
      title: Text(
        description.isEmpty
            ? item['category'] as String? ?? 'Transaction'
            : description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${item['category']} · $date'),
      trailing: Text(
        '${income ? '+' : '−'}${_dashboardMoney(item['amount_minor'] as int? ?? 0)}',
        style: TextStyle(
          color: income ? const Color(0xFF3D8060) : const Color(0xFF1D2924),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _dashboardMoney(int minor) {
    final absolute = minor.abs();
    final whole = (absolute ~/ 100).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final fraction = absolute % 100;
    return '${minor < 0 ? '−' : ''}₸ $whole${fraction == 0 ? '' : '.${fraction.toString().padLeft(2, '0')}'}';
  }

  String _compactMoney(int minor) {
    final amount = minor / 100;
    if (amount.abs() >= 1000000) {
      return '₸${(amount / 1000000).toStringAsFixed(1)}m';
    }
    if (amount.abs() >= 1000) {
      return '₸${(amount / 1000).toStringAsFixed(amount.abs() >= 10000 ? 0 : 1)}k';
    }
    return _dashboardMoney(minor);
  }

  Widget _transactions() {
    final currentMonth = DateTime.now().toUtc().toIso8601String().substring(
      0,
      7,
    );
    final monthTransactions = items.where((item) {
      final created = item['created_at'] as String? ?? '';
      return created.startsWith(currentMonth);
    });
    final monthIncome = monthTransactions
        .where((item) => item['kind'] == 'income')
        .fold<int>(0, (sum, item) => sum + (item['amount_minor'] as int? ?? 0));
    final monthExpenses = monthTransactions
        .where((item) => item['kind'] == 'expense')
        .fold<int>(0, (sum, item) => sum + (item['amount_minor'] as int? ?? 0));
    final categoryCount = items
        .map((item) => item['category'] as String? ?? '')
        .where((category) => category.isNotEmpty)
        .toSet()
        .length;
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _pageIntro(
          'YOUR MONEY MOVEMENT',
          'Transactions',
          'All your income and expenses, in one place.',
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 142,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _transactionStatCard(
                'Income this month',
                _dashboardMoney(monthIncome),
                Icons.south_west,
                const Color(0xFFE7F4E9),
                detail: currentMonth,
              ),
              const SizedBox(width: 12),
              _transactionStatCard(
                'Expenses this month',
                _dashboardMoney(monthExpenses),
                Icons.north_east,
                const Color(0xFFFBF0E6),
                detail: currentMonth,
              ),
              const SizedBox(width: 12),
              _transactionStatCard(
                'Transactions',
                '${items.length}',
                Icons.swap_vert,
                const Color(0xFFF1F5F2),
                detail: 'Across $categoryCount categories',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          color: const Color(0xFFF2F9F4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE1F0E5),
                  child: Icon(
                    Icons.document_scanner_outlined,
                    color: Color(0xFF245B48),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan a receipt',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Recognize the details, review them, then save.',
                        style: TextStyle(
                          color: Color(0xFF87928C),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Recognize receipt',
                  onPressed: () => add(scanReceipt: true),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search transactions',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF7F9F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final entry in {
                        'all': 'All',
                        'income': 'Income',
                        'expense': 'Expenses',
                      }.entries)
                        FilterChip(
                          label: Text(entry.value),
                          selected: kindFilter == entry.key,
                          onSelected: (_) =>
                              setState(() => kindFilter = entry.key),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${visible.length} ${visible.length == 1 ? 'transaction' : 'transactions'}',
                    style: const TextStyle(
                      color: Color(0xFF87928C),
                      fontSize: 12,
                    ),
                  ),
                ),
                const Text(
                  'Amounts in KZT (₸)',
                  style: TextStyle(color: Color(0xFF87928C), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          _emptyPanel(
            Icons.receipt_long_outlined,
            'No transactions yet',
            'Add your first income or expense to see it here.',
          )
        else if (visible.isEmpty)
          _emptyPanel(
            Icons.search_off,
            'No matching transactions',
            'Try another search or change the filters.',
          )
        else
          Card(
            child: Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  _transactionRow(visible[index]),
                  if (index < visible.length - 1)
                    const Divider(height: 1, indent: 72),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _transactionStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor, {
    required String detail,
  }) => SizedBox(
    width: 224,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF87928C),
                      fontSize: 12,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 15,
                  backgroundColor: iconColor,
                  child: Icon(icon, size: 16, color: const Color(0xFF3D8060)),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: const TextStyle(color: Color(0xFF87928C), fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _transactionRow(Map<String, dynamic> item) {
    final expense = item['kind'] == 'expense';
    final description = (item['description'] as String? ?? '').trim();
    final date = (item['created_at'] as String? ?? '')
        .split(RegExp('[T ]'))
        .first;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: expense
            ? const Color(0xFFFBF0E6)
            : const Color(0xFFE7F4E9),
        child: Icon(
          expense ? Icons.north_east : Icons.south_west,
          color: expense ? const Color(0xFFC78545) : const Color(0xFF3D8060),
          size: 18,
        ),
      ),
      title: Text(
        description.isEmpty ? item['category'] as String : description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${item['category']} · $date'),
      trailing: Text(
        '${expense ? '−' : '+'}${_dashboardMoney(item['amount_minor'] as int)}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: expense ? const Color(0xFF1D2924) : const Color(0xFF3D8060),
        ),
      ),
    );
  }

  Widget _pageIntro(String eyebrow, String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: Color(0xFF87928C),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: Color(0xFF87928C))),
    ],
  );

  Widget _emptyPanel(IconData icon, String title, String subtitle) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 30, color: const Color(0xFF87928C)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF87928C)),
          ),
        ],
      ),
    ),
  );

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
    final totalExpenses = categories.fold<int>(
      0,
      (sum, category) => sum + (category['amount_minor'] as int? ?? 0),
    );
    final topCategory = categories.isEmpty ? null : categories.first;
    final monthKey = DateTime.now().toUtc().toIso8601String().substring(0, 7);
    final monthSpend = items
        .where(
          (item) =>
              item['kind'] == 'expense' &&
              (item['created_at'] as String? ?? '').startsWith(monthKey),
        )
        .fold<int>(0, (sum, item) => sum + (item['amount_minor'] as int? ?? 0));
    final dayOfMonth = DateTime.now().toUtc().day;
    final averageDaily = dayOfMonth == 0 ? 0 : monthSpend ~/ dayOfMonth;
    final budgetWarnings = budgets.where((budget) {
      final amount = budget['amount_minor'] as int? ?? 0;
      final spent = budget['spent_minor'] as int? ?? 0;
      return amount > 0 && spent * 100 >= amount * 80;
    }).toList();
    final peak = months.fold<int>(
      1,
      (value, month) => (month['expense_minor'] as int) > value
          ? month['expense_minor'] as int
          : value,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _pageIntro(
          'UNDERSTAND YOUR HABITS',
          'Spending insights',
          'See where your money goes and how your spending changes.',
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 142,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _transactionStatCard(
                'Average daily spend',
                _dashboardMoney(averageDaily),
                Icons.schedule,
                const Color(0xFFF1F5F2),
                detail: 'Based on $dayOfMonth days this month',
              ),
              const SizedBox(width: 12),
              _transactionStatCard(
                'Top category',
                topCategory?['category'] as String? ?? '—',
                Icons.category_outlined,
                const Color(0xFFFBF0E6),
                detail: topCategory == null
                    ? 'No expenses recorded'
                    : '${((topCategory['share'] as num) * 100).round()}% of expenses',
              ),
              const SizedBox(width: 12),
              _transactionStatCard(
                'Expense estimate',
                forecast['status'] == 'ok'
                    ? _dashboardMoney(forecast['forecast_minor'] as int)
                    : '—',
                Icons.auto_graph,
                const Color(0xFFE7F4E9),
                detail: forecast['status'] == 'ok'
                    ? 'Forecast for ${forecast['forecast_month']}'
                    : 'More history needed',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expenses by category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                if (categories.isEmpty)
                  const Text(
                    'Add an expense to see where your money goes.',
                    style: TextStyle(color: Color(0xFF87928C)),
                  ),
                if (categories.isNotEmpty) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 132,
                        height: 132,
                        child: CustomPaint(
                          painter: _CategoryDonutPainter(
                            categories
                                .map((category) => category['share'] as num)
                                .toList(),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _compactMoney(totalExpenses),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  'Total spent',
                                  style: TextStyle(
                                    color: Color(0xFF87928C),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            for (final entry in categories.take(5))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color:
                                            _categoryColors[categories.indexOf(
                                                  entry,
                                                ) %
                                                _categoryColors.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        entry['category'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    Text(
                                      _compactMoney(
                                        entry['amount_minor'] as int,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                category['category'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${((category['share'] as num) * 100).round()}%',
                              style: const TextStyle(
                                color: Color(0xFF87928C),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _dashboardMoney(category['amount_minor'] as int),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: (category['share'] as num).toDouble(),
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE9F0EA),
                            color: const Color(0xFF3D8060),
                            semanticsLabel:
                                '${category['category']} share of expenses',
                            semanticsValue:
                                '${((category['share'] as num) * 100).round()}%',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Smart observations',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Icon(Icons.auto_awesome, color: Color(0xFFC78545)),
                  ],
                ),
                const SizedBox(height: 8),
                if (budgetWarnings.isEmpty)
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF3D8060),
                    ),
                    title: Text(
                      'Keep building your financial picture',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Record transactions and set budgets to get useful spending insights.',
                    ),
                  )
                else
                  for (final budget in budgetWarnings)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        budget['over_budget'] == true
                            ? Icons.warning_amber
                            : Icons.trending_up,
                        color: budget['over_budget'] == true
                            ? const Color(0xFFC96A56)
                            : const Color(0xFFC78545),
                      ),
                      title: Text(
                        budget['category'] == '*'
                            ? 'Monthly budget'
                            : budget['category'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        budget['over_budget'] == true
                            ? 'This budget is over its limit by ${money(-(budget['remaining_minor'] as int))}.'
                            : 'You have used ${(budget['spent_minor'] as int) * 100 ~/ (budget['amount_minor'] as int)}% of this budget.',
                      ),
                    ),
                const Text(
                  'Estimates are based on recorded transactions and are not financial advice.',
                  style: TextStyle(color: Color(0xFF87928C), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly expenses',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                if (months.isEmpty)
                  const Text(
                    'No monthly expense data yet.',
                    style: TextStyle(color: Color(0xFF87928C)),
                  ),
                for (final month in months)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(month['month'] as String)),
                            Text(
                              money(month['expense_minor'] as int),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: (month['expense_minor'] as int) / peak,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE9F0EA),
                            color: const Color(0xFFBCD8C5),
                            semanticsLabel: '${month['month']} expenses',
                            semanticsValue:
                                '${((month['expense_minor'] as int) * 100 / peak).round()}%',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          color: const Color(0xFFEDF5EF),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense estimate',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (forecast['status'] == 'ok') ...[
                  Text(
                    '${forecast['forecast_month']}: ${money(forecast['forecast_minor'] as int)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF245B48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Average of the previous three complete months. Missing months count as zero, so keep your diary complete. Actual expenses may differ.',
                    style: TextStyle(color: Color(0xFF647269)),
                  ),
                ] else
                  Text(
                    forecast['status'] == 'unavailable'
                        ? 'Forecasting is not available yet.'
                        : 'Record expenses across at least three complete months to see an estimate.',
                    style: const TextStyle(color: Color(0xFF647269)),
                  ),
              ],
            ),
          ),
        ),
        if (((insights!['recommendations'] as List?) ?? []).isNotEmpty) ...[
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending observations',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (final note
                      in (insights!['recommendations'] as List).cast<String>())
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFFC78545),
                      ),
                      title: Text(note),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF87928C)),
      ),
    ],
  );
}

class _CategoryDonutPainter extends CustomPainter {
  const _CategoryDonutPainter(this.shares);
  final List<num> shares;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      rect.deflate(12),
      -math.pi / 2,
      math.pi * 2,
      false,
      paint..color = const Color(0xFFE9F0EA),
    );
    var start = -math.pi / 2;
    for (var index = 0; index < shares.length; index++) {
      final sweep = shares[index].toDouble().clamp(0, 1) * math.pi * 2;
      if (sweep > 0) {
        canvas.drawArc(
          rect.deflate(12),
          start,
          sweep,
          false,
          paint..color = _categoryColors[index % _categoryColors.length],
        );
        start += sweep;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryDonutPainter oldDelegate) =>
      oldDelegate.shares != shares;
}

class AddPage extends StatefulWidget {
  const AddPage({
    super.key,
    required this.api,
    this.pickPhoto,
    this.categories = expenseCategories,
    this.startReceiptScanner = false,
  });
  final FinanceApi api;
  final ReceiptPhotoPicker? pickPhoto;
  final List<String> categories;
  final bool startReceiptScanner;
  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  final category = TextEditingController();
  final description = TextEditingController();
  final merchant = TextEditingController();
  final receiptDate = TextEditingController();
  final receiptTotal = TextEditingController();
  bool scanned = false;
  String? receiptCurrency;
  String? rememberedCategory;
  String kind = 'expense';
  DateTime date = DateTime.now().toUtc();
  bool saving = false;
  bool suggesting = false;
  String? error;
  String? suggestion;

  @override
  void initState() {
    super.initState();
    if (widget.startReceiptScanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) scanReceipt();
      });
    }
  }

  @override
  void dispose() {
    amount.dispose();
    category.dispose();
    description.dispose();
    merchant.dispose();
    receiptDate.dispose();
    receiptTotal.dispose();
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

  Future<void> scanReceipt() async {
    final receipt = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) =>
            ReceiptScanPage(api: widget.api, pickPhoto: widget.pickPhoto),
      ),
    );
    if (receipt == null || !mounted) return;
    setState(() {
      scanned = true;
      kind = 'expense';
      merchant.text = receipt['merchant'] as String? ?? '';
      receiptDate.text = receipt['date'] as String? ?? '';
      receiptCurrency = receipt['currency'] as String?;
      final total = receipt['total'] as num?;
      receiptTotal.text = total?.toStringAsFixed(2) ?? '';
      amount.text = receiptCurrency == 'KZT' ? receiptTotal.text : '';
      category.text = receipt['category'] as String? ?? '';
      rememberedCategory = receipt['category_source'] == 'remembered'
          ? category.text
          : null;
      suggestion = null;
      error = null;
    });
  }

  String? receiptDateError(String? value) {
    final input = (value ?? '').trim();
    final parsed = DateTime.tryParse(input);
    final today = DateTime.now().toUtc();
    final currentDay = DateTime.utc(today.year, today.month, today.day);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input) ||
        parsed == null ||
        dateText(parsed) != input) {
      return 'Enter a valid date as YYYY-MM-DD.';
    }
    final day = DateTime.utc(parsed.year, parsed.month, parsed.day);
    if (day.isAfter(currentDay) ||
        day.isBefore(currentDay.subtract(const Duration(days: 3653)))) {
      return 'Choose a date within the last ten years, up to today.';
    }
    return null;
  }

  Widget receiptCategoryPicker() => FormField<String>(
    validator: (_) =>
        category.text.trim().isEmpty ? 'Choose a category.' : null,
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category (required)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in {
              ...widget.categories,
              if (category.text.isNotEmpty) category.text,
            })
              ChoiceChip(
                label: Text(name),
                selected: category.text == name,
                onSelected: saving
                    ? null
                    : (_) {
                        setState(() => category.text = name);
                        field.didChange(name);
                      },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          rememberedCategory != null && category.text == rememberedCategory
              ? 'Remembered category. Tap a chip to change it.'
              : 'This category will be remembered for this merchant when saved.',
        ),
        if (field.hasError)
          Text(
            field.errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
  );

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
        'description': scanned
            ? '${merchant.text.trim()}${receiptCurrency == 'KZT' ? '' : ' (${receiptTotal.text.trim()} $receiptCurrency)'}${description.text.trim().isEmpty ? '' : ' - ${description.text.trim()}'}'
            : description.text.trim(),
        'date': scanned ? receiptDate.text.trim() : dateText(date),
        if (scanned) 'merchant': merchant.text.trim(),
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
    appBar: AppBar(title: Text(scanned ? 'Review receipt' : 'Add transaction')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  scanned ? 'REVIEW YOUR RECEIPT' : 'ADD TO YOUR LEDGER',
                  style: const TextStyle(
                    color: Color(0xFF87928C),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scanned ? 'Review transaction' : 'New transaction',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scanned
                      ? 'Check the details before saving.'
                      : 'Record income or an expense in a few steps.',
                  style: const TextStyle(color: Color(0xFF87928C)),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (kind == 'expense') ...[
                          OutlinedButton.icon(
                            onPressed: saving || suggesting
                                ? null
                                : scanReceipt,
                            icon: const Icon(Icons.document_scanner_outlined),
                            label: Text(
                              scanned ? 'Scan another receipt' : 'Scan receipt',
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (scanned) ...[
                          const Text(
                            'Review every field. Empty fields need your input. Nothing is saved until you tap Save transaction.',
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const ValueKey('receipt-merchant'),
                            controller: merchant,
                            enabled: !saving,
                            maxLength: 200,
                            decoration: const InputDecoration(
                              labelText: 'Merchant',
                            ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Enter the merchant name.'
                                : null,
                            onChanged: (_) => setState(() {
                              category.clear();
                              rememberedCategory = null;
                            }),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            key: ValueKey(receiptCurrency),
                            initialValue: receiptCurrency,
                            decoration: const InputDecoration(
                              labelText: 'Receipt currency',
                            ),
                            items: [
                              for (final code in ['KZT', 'RUB', 'USD', 'EUR'])
                                DropdownMenuItem(
                                  value: code,
                                  child: Text(code),
                                ),
                            ],
                            validator: (value) => value == null
                                ? 'Choose the receipt currency.'
                                : null,
                            onChanged: saving
                                ? null
                                : (value) => setState(() {
                                    receiptCurrency = value;
                                    amount.text = value == 'KZT'
                                        ? receiptTotal.text
                                        : '';
                                  }),
                          ),
                          if (receiptCurrency != 'KZT') ...[
                            const SizedBox(height: 20),
                            TextFormField(
                              key: const ValueKey('receipt-total'),
                              controller: receiptTotal,
                              enabled: !saving,
                              decoration: const InputDecoration(
                                labelText: 'Original receipt total',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) =>
                                  parseAmount(value ?? '') == null
                                  ? 'Enter the positive receipt total.'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Your ledger uses KZT. Enter the converted KZT amount below. Currency conversion is manual.',
                            ),
                          ],
                          const SizedBox(height: 20),
                        ] else
                          DropdownButtonFormField<String>(
                            initialValue: kind,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'expense',
                                child: Text('Expense'),
                              ),
                              DropdownMenuItem(
                                value: 'income',
                                child: Text('Income'),
                              ),
                            ],
                            onChanged: saving
                                ? null
                                : (value) => setState(() => kind = value!),
                          ),
                        const SizedBox(height: 20),
                        TextFormField(
                          key: const ValueKey('transaction-amount'),
                          controller: amount,
                          enabled: !saving,
                          decoration: const InputDecoration(
                            labelText: 'Amount in KZT',
                            hintText: '1500.00',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (value) {
                            if (scanned && receiptCurrency == 'KZT') {
                              receiptTotal.text = value;
                            }
                          },
                          validator: (value) => parseAmount(value ?? '') == null
                              ? 'Enter a positive amount with up to two decimal places.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        if (scanned)
                          TextFormField(
                            key: const ValueKey('receipt-date'),
                            controller: receiptDate,
                            enabled: !saving,
                            decoration: const InputDecoration(
                              labelText: 'Purchase date',
                              hintText: 'YYYY-MM-DD',
                            ),
                            validator: receiptDateError,
                          )
                        else
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
                        if (scanned)
                          receiptCategoryPicker()
                        else
                          TextFormField(
                            controller: category,
                            enabled: !saving && !suggesting,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              hintText: 'Groceries',
                            ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Enter a category.'
                                : null,
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: description,
                          enabled: !saving && !suggesting,
                          maxLength: scanned ? 700 : 1000,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description (optional)',
                          ),
                        ),
                        if (kind == 'expense' && !scanned) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: saving || suggesting ? null : suggest,
                              icon: const Icon(Icons.auto_fix_high),
                              label: Text(
                                suggesting
                                    ? 'Finding a category...'
                                    : 'Suggest category',
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
                          child: Text(
                            saving ? 'Saving...' : 'Save transaction',
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
      ),
    ),
  );
}
