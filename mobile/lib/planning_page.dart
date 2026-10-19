import 'package:flutter/material.dart';
import 'api.dart';
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
      children: [
        Text('Planning', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Text('Budgets · $month', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Category budgets use the same category names as your expenses. An overall budget covers all expenses.',
        ),
        if (budgets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No budget set for this month.'),
          ),
        for (final budget in budgets)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget['category'] == '*'
                      ? 'All expenses'
                      : budget['category'] as String,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${money(budget['spent_minor'] as int)} spent of ${money(budget['amount_minor'] as int)}',
                ),
                if (budget['over_budget'] == true)
                  Text(
                    'Above budget by ${money(-(budget['remaining_minor'] as int))}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                else
                  Text('${money(budget['remaining_minor'] as int)} remaining'),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => add(false),
            icon: const Icon(Icons.add),
            label: const Text('Set a budget'),
          ),
        ),
        const Divider(height: 40),
        Text('Savings goals', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Track amounts you have set aside. Updating a goal does not move money or change your transactions.',
        ),
        if (goals.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Add a goal to track your progress.'),
          ),
        for (final goal in goals)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal['name'] as String,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${money(goal['saved_minor'] as int)} of ${money(goal['target_minor'] as int)}',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value:
                      (goal['saved_minor'] as int) /
                      (goal['target_minor'] as int),
                  semanticsLabel: '${goal['name']} progress',
                ),
                Semantics(
                  container: true,
                  explicitChildNodes: true,
                  child: TextButton(
                    onPressed: () => update(goal),
                    child: Text(
                      goal['saved_minor'] == goal['target_minor']
                          ? 'Goal reached · update amount'
                          : 'Update saved amount',
                    ),
                  ),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => add(true),
            icon: const Icon(Icons.add),
            label: const Text('Add a savings goal'),
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
            padding: const EdgeInsets.all(24),
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
                    labelText: widget.goal ? 'Goal name' : 'Expense category',
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Enter a name.' : null,
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
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                widget.goal['name'] as String,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('Target: ${money(widget.goal['target_minor'] as int)}'),
              const SizedBox(height: 24),
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
                  if (RegExp(r'^0(\.0{1,2})?$').hasMatch(text)) return null;
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
    ),
  );
}
