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
    body: SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Smart Finance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1D2924),
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Form(
                        key: form,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                registering
                                    ? 'Create your account'
                                    : 'Your finances, in one place',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1D2924),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                registering
                                    ? 'Create an account to keep track of your transactions and spending insights.'
                                    : 'Sign in to view your transactions and spending insights.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF26332D),
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: username,
                                enabled: !busy,
                                autocorrect: false,
                                autofillHints: const [AutofillHints.username],
                                decoration: _authDecoration('Username'),
                                validator: (value) =>
                                    RegExp(
                                      r'^[A-Za-z0-9_]{3,40}$',
                                    ).hasMatch(value?.trim() ?? '')
                                    ? null
                                    : 'Use 3–40 letters, numbers, or underscores.',
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: password,
                                enabled: !busy,
                                obscureText: true,
                                autofillHints: [
                                  registering
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                decoration: _authDecoration('Password')
                                    .copyWith(
                                      helperText: 'At least 10 characters',
                                      helperStyle: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF647269),
                                      ),
                                    ),
                                onFieldSubmitted: (_) => submit(),
                                validator: (value) =>
                                    (value?.length ?? 0) >= 10 &&
                                        (value?.length ?? 0) <= 128
                                    ? null
                                    : 'Use 10–128 characters.',
                              ),
                              if (error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      error!,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 46,
                                child: FilledButton(
                                  onPressed: busy ? null : submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF176E53),
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(
                                    busy
                                        ? 'Please wait...'
                                        : registering
                                        ? 'Create account'
                                        : 'Sign in',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => setState(() {
                                        registering = !registering;
                                        error = null;
                                      }),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF176E53),
                                ),
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  InputDecoration _authDecoration(String label) => InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFF77847D)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFF176E53), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.error,
        width: 1.5,
      ),
    ),
  );
}
