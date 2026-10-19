import 'package:flutter/material.dart';
import 'api.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.api, required this.onSignedIn});
  final FinanceApi api;
  final void Function(String token) onSignedIn;
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final form = GlobalKey<FormState>();
  final username = TextEditingController();
  final password = TextEditingController();
  bool registering = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.api.post(
        registering ? '/auth/register' : '/auth/login',
        {'username': username.text.trim(), 'password': password.text},
        expectedStatus: registering ? 201 : 200,
      );
      if (mounted) widget.onSignedIn(result['token'] as String);
    } catch (failure) {
      if (mounted) {
        setState(
          () => error = failure is ApiFailure
              ? failure.message
              : 'Could not connect. Check the server, then try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Smart Finance')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: form,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                registering
                    ? 'Create your account'
                    : 'Your finances, in one place',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                registering
                    ? 'Keep a personal record of income, expenses, budgets, and savings goals.'
                    : 'Sign in to view your transactions and spending insights.',
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: username,
                enabled: !busy,
                autocorrect: false,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) =>
                    RegExp(
                      r'^[A-Za-z0-9_]{3,40}$',
                    ).hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Use 3–40 letters, numbers, or underscores.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: password,
                enabled: !busy,
                obscureText: true,
                autofillHints: [
                  registering
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                decoration: const InputDecoration(
                  labelText: 'Password',
                  helperText: 'At least 10 characters',
                ),
                onFieldSubmitted: (_) => submit(),
                validator: (value) =>
                    (value?.length ?? 0) >= 10 && (value?.length ?? 0) <= 128
                    ? null
                    : 'Use 10–128 characters.',
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: busy ? null : submit,
                child: Text(
                  busy
                      ? 'Please wait...'
                      : registering
                      ? 'Create account'
                      : 'Sign in',
                ),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                        registering = !registering;
                        error = null;
                      }),
                child: Text(
                  registering
                      ? 'Already have an account? Sign in'
                      : 'New here? Create an account',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
