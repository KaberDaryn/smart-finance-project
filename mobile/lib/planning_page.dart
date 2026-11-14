import 'package:flutter/material.dart';
import 'api.dart';
import 'design_system.dart';
import 'formatters.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key, required this.api});
  final FinanceApi api;
  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> goals = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final replies = await Future.wait([
        widget.api.get('/budgets'),
        widget.api.get('/goals'),
      ]);
      if (mounted) {
        setState(() {
          budgets = (replies[0] as List).cast<Map<String, dynamic>>();
          goals = (replies[1] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Planning is unavailable. Check the connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> add(bool goal) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlanningForm(api: widget.api, goal: goal),
      ),
    );
    if (saved == true && mounted) await load();
  }

  Future<void> update(Map<String, dynamic> goal) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GoalProgressForm(api: widget.api, goal: goal),
      ),
    );
    if (saved == true && mounted) await load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(24), child: Text(error!)),
            FilledButton(onPressed: load, child: const Text('Try again')),
          ],
        ),
      );
    }
    final month = dateText(DateTime.now().toUtc()).substring(0, 7);
    final limit = budgets.fold<int>(
      0,
      (sum, budget) => sum + (budget['amount_minor'] as int? ?? 0),
    );
    final spent = budgets.fold<int>(
      0,
      (sum, budget) => sum + (budget['spent_minor'] as int? ?? 0),
    );
    final saved = goals.fold<int>(
      0,
      (sum, goal) => sum + (goal['saved_minor'] as int? ?? 0),
    );
    final percent = limit == 0 ? 0.0 : (spent / limit).clamp(0, 1).toDouble();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        const SFPageHeader(
          eyebrow: 'MAKE YOUR MONEY GO FURTHER',
          title: 'Planning',
          subtitle: 'Build better habits one month at a time.',
        ),
        const SizedBox(height: 16),
        SFPanel(
          gradient: SFColors.gradHero,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Budget used · $month',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                  Text(
                    sfMoney(spent),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    limit == 0 ? '' : '${(spent * 100 / limit).round()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9FE8C0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    FractionallySizedBox(
                      widthFactor: percent,
                      child: Container(
                        height: 6,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF58C493), Color(0xFF9FE8C0)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${goals.isEmpty ? 'No savings goals yet' : '${sfMoney(saved)} saved toward goals'}'
                '${limit == 0 ? '' : ' · ${sfMoney(limit)} limit'}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
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
                            'Monthly budgets',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track spending against your limits · $month',
                            style: const TextStyle(
                              color: Color(0xFF87928C),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Set a budget',
                      onPressed: () => add(false),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                if (budgets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No budget set for this month.',
                      style: TextStyle(color: Color(0xFF87928C)),
                    ),
                  ),
                for (final budget in budgets)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SFCategoryIcon(
                              category: budget['category'] as String?,
                              size: 34,
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                budget['category'] == '*'
                                    ? 'All expenses'
                                    : budget['category'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${money(budget['spent_minor'] as int)} / ${money(budget['amount_minor'] as int)}',
                              style: const TextStyle(
                                color: SFColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        SFProgressBar(
                          value:
                              ((budget['spent_minor'] as int) /
                                      (budget['amount_minor'] as int))
                                  .clamp(0, 1)
                                  .toDouble(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          budget['over_budget'] == true
                              ? 'Above budget by ${money(-(budget['remaining_minor'] as int))}'
                              : '${money(budget['remaining_minor'] as int)} remaining',
                          style: TextStyle(
                            color: budget['over_budget'] == true
                                ? SFColors.danger
                                : SFColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => add(false),
                  icon: const Icon(Icons.add),
                  label: const Text('Set a budget'),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Savings goals',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Keep your goals in sight as you save.',
                            style: TextStyle(
                              color: Color(0xFF87928C),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add a savings goal',
                      onPressed: () => add(true),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                if (goals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Add a goal to track your progress.',
                      style: TextStyle(color: Color(0xFF87928C)),
                    ),
                  ),
                for (final goal in goals)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SFRing(
                          value:
                              ((goal['saved_minor'] as int) /
                                      (goal['target_minor'] as int))
                                  .clamp(0, 1)
                                  .toDouble(),
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${money(goal['saved_minor'] as int)} / ${money(goal['target_minor'] as int)}',
                                style: const TextStyle(
                                  color: SFColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 9),
                              SFProgressBar(
                                value:
                                    ((goal['saved_minor'] as int) /
                                            (goal['target_minor'] as int))
                                        .clamp(0, 1)
                                        .toDouble(),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => update(goal),
                                  child: Text(
                                    goal['saved_minor'] == goal['target_minor']
                                        ? 'Goal reached · update amount'
                                        : 'Update progress',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => add(true),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a savings goal'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PlanningForm extends StatefulWidget {
  const PlanningForm({super.key, required this.api, required this.goal});
  final FinanceApi api;
  final bool goal;
  @override
  State<PlanningForm> createState() => _PlanningFormState();
}

class _PlanningFormState extends State<PlanningForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final amount = TextEditingController();
  bool overall = true;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final minor = parseAmount(amount.text);
      await widget.api.post(
        widget.goal ? '/goals' : '/budgets',
        widget.goal
            ? {'name': name.text.trim(), 'target_minor': minor}
            : {
                'month': dateText(DateTime.now().toUtc()).substring(0, 7),
                'category': overall ? '*' : name.text.trim(),
                'amount_minor': minor,
              },
        expectedStatus: widget.goal ? 201 : 200,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (failure) {
      if (mounted) {
        setState(
          () => error = failure is ApiFailure
              ? failure.message
              : 'Could not save. Check the connection, then try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.goal ? 'Add a savings goal' : 'Set a monthly budget'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text(
                widget.goal ? 'BUILD YOUR FUTURE' : 'PLAN YOUR SPENDING',
                style: const TextStyle(
                  color: Color(0xFF87928C),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.goal ? 'New savings goal' : 'Monthly budget',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.goal
                    ? 'Choose a target and keep track of your progress.'
                    : 'Set a limit that works for your monthly expenses.',
                style: const TextStyle(color: Color(0xFF87928C)),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!widget.goal)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Cover all expenses'),
                          value: overall,
                          onChanged: busy
                              ? null
                              : (value) => setState(() => overall = value),
                        ),
                      if (widget.goal || !overall) ...[
                        TextFormField(
                          controller: name,
                          enabled: !busy,
                          maxLength: 100,
                          decoration: InputDecoration(
                            labelText: widget.goal
                                ? 'Goal name'
                                : 'Expense category',
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Enter a name.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                      ],
                      TextFormField(
                        controller: amount,
                        enabled: !busy,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: widget.goal
                              ? 'Target amount in KZT'
                              : 'Monthly limit in KZT',
                        ),
                        validator: (value) => parseAmount(value ?? '') == null
                            ? 'Enter a positive amount with up to two decimal places.'
                            : null,
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: busy ? null : save,
                        child: Text(busy ? 'Saving...' : 'Save'),
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
  );
}

class GoalProgressForm extends StatefulWidget {
  const GoalProgressForm({super.key, required this.api, required this.goal});
  final FinanceApi api;
  final Map<String, dynamic> goal;
  @override
  State<GoalProgressForm> createState() => _GoalProgressFormState();
}

class _GoalProgressFormState extends State<GoalProgressForm> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    amount.text = ((widget.goal['saved_minor'] as int) / 100).toStringAsFixed(
      2,
    );
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final saved = RegExp(r'^0(\.0{1,2})?$').hasMatch(amount.text.trim())
          ? 0
          : parseAmount(amount.text);
      await widget.api.post('/goals/update', {
        'id': widget.goal['id'],
        'saved_minor': saved,
      }, expectedStatus: 200);
      if (mounted) Navigator.pop(context, true);
    } catch (failure) {
      if (mounted) {
        setState(
          () => error = failure is ApiFailure
              ? failure.message
              : 'Could not update the goal. Check your connection.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Update savings progress')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              const Text(
                'MAKE YOUR MONEY GO FURTHER',
                style: TextStyle(
                  color: Color(0xFF87928C),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update savings progress',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.goal['name'] as String,
                style: const TextStyle(color: Color(0xFF87928C)),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Target: ${money(widget.goal['target_minor'] as int)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: amount,
                        enabled: !busy,
                        decoration: const InputDecoration(
                          labelText: 'Total saved in KZT',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (RegExp(r'^0(\.0{1,2})?$').hasMatch(text)) {
                            return null;
                          }
                          final minor = parseAmount(text);
                          return minor == null ||
                                  minor > (widget.goal['target_minor'] as int)
                              ? 'Enter an amount between zero and the target.'
                              : null;
                        },
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(error!),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: busy ? null : save,
                        child: Text(busy ? 'Saving...' : 'Save progress'),
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
  );
}
