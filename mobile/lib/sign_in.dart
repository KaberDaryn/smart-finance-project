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
  static const _background = Color(0xFF0C0E12);
  static const _card = Color(0xFF151820);
  static const _field = Color(0xFF20232B);
  static const _line = Color(0xFF3A3F49);
  static const _ink = Color(0xFFF0EDE6);
  static const _muted = Color(0xFF9C978B);
  static const _faint = Color(0xFF6E6A5F);
  static const _buttonStart = Color(0xFFDCE3EB);
  static const _buttonEnd = Color(0xFFA0AAB9);

  final form = GlobalKey<FormState>();
  final username = TextEditingController();
  final password = TextEditingController();
  bool registering = false;
  bool busy = false;
  bool obscurePassword = true;
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
    backgroundColor: _background,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: constraints.maxHeight > 700 ? 28 : 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _line),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 48,
                      offset: Offset(0, 22),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SparkMark(),
                        const SizedBox(height: 22),
                        Text(
                          registering ? 'Create your account' : 'Welcome back',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 28,
                            height: 1.12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          registering
                              ? 'Create an account to manage your personal finances.'
                              : 'Sign in to your personal finance workspace.',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 26),
                        _fieldLabel('Username'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: username,
                          enabled: !busy,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.username],
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _decoration(
                            'e.g. daryn',
                            Icons.person_outline,
                          ),
                          validator: (value) =>
                              RegExp(
                                r'^[A-Za-z0-9_]{3,40}$',
                              ).hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Use 3–40 letters, numbers, or underscores.',
                        ),
                        const SizedBox(height: 17),
                        _fieldLabel('Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: password,
                          enabled: !busy,
                          obscureText: obscurePassword,
                          autofillHints: [
                            registering
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration:
                              _decoration(
                                '10–128 characters',
                                Icons.account_balance_wallet_outlined,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => obscurePassword = !obscurePassword,
                                  ),
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 19,
                                    color: _muted,
                                  ),
                                ),
                              ),
                          validator: (value) =>
                              (value?.length ?? 0) >= 10 &&
                                  (value?.length ?? 0) <= 128
                              ? null
                              : 'Use 10–128 characters.',
                          onFieldSubmitted: (_) => submit(),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF321D23),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF683640),
                              ),
                            ),
                            child: Text(
                              error!,
                              style: const TextStyle(
                                color: Color(0xFFFFB4AB),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 32,
                              child: Checkbox(
                                value: registering,
                                onChanged: busy
                                    ? null
                                    : (value) => setState(() {
                                        registering = value ?? false;
                                        error = null;
                                      }),
                                side: const BorderSide(
                                  color: Color(0xFFB9B7B0),
                                  width: 1.5,
                                ),
                                activeColor: _buttonStart,
                                checkColor: _background,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 9),
                            GestureDetector(
                              onTap: busy
                                  ? null
                                  : () => setState(() {
                                      registering = !registering;
                                      error = null;
                                    }),
                              child: const Text(
                                'Create a new account',
                                style: TextStyle(color: _muted, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_buttonStart, _buttonEnd],
                              ),
                              borderRadius: BorderRadius.circular(17),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x267F8FA5),
                                  blurRadius: 20,
                                  offset: Offset(0, 7),
                                ),
                              ],
                            ),
                            child: FilledButton(
                              onPressed: busy ? null : submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                foregroundColor: const Color(0xFF171A20),
                                disabledForegroundColor: const Color(
                                  0xFF171A20,
                                ),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
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
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Your data stays in the local Smart Finance backend. '
                          'Passwords are stored salted & hashed.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _faint,
                            fontSize: 12,
                            height: 1.45,
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
  );

  Widget _fieldLabel(String label) => Text(
    label,
    style: const TextStyle(
      color: _muted,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _muted, fontWeight: FontWeight.w500),
    prefixIcon: Icon(icon, size: 18, color: _muted),
    filled: true,
    fillColor: _field,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF343841)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFAEB8C4), width: 1.3),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE07A7A)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE07A7A), width: 1.3),
    ),
  );
}

class _SparkMark extends StatelessWidget {
  const _SparkMark();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0E6EE), Color(0xFFA0AAB9)],
        ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x668F9BAD),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
    ),
  );
}
