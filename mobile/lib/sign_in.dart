import 'package:flutter/material.dart';
import 'api.dart';
import 'design_system.dart';

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
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final wide = MediaQuery.of(context).size.width >= 640;
    final formCard = _authCard(context, ink, wide);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            const Expanded(flex: 5, child: _BrandHero()),
            Expanded(
              flex: 6,
              child: Center(child: SingleChildScrollView(child: formCard)),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandBadge(),
                    const SizedBox(height: 18),
                    formCard,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _authCard(BuildContext context, Color ink, bool wide) {
    final card = Padding(
      padding: EdgeInsets.all(wide ? 30 : 22),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              registering
                  ? 'Create your account'
                  : 'Your finances, in one place',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              registering
                  ? 'Create an account to keep track of your transactions and spending insights.'
                  : 'Sign in to view your transactions and spending insights.',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: SFColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: username,
              enabled: !busy,
              autocorrect: false,
              autofillHints: const [AutofillHints.username],
              decoration: _authDecoration('Username', Icons.person_outline),
              validator: (value) =>
                  RegExp(r'^[A-Za-z0-9_]{3,40}$').hasMatch(value?.trim() ?? '')
                  ? null
                  : 'Use 3–40 letters, numbers, or underscores.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: password,
              enabled: !busy,
              obscureText: obscurePassword,
              autofillHints: [
                registering
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              decoration: _authDecoration('Password', Icons.lock_outline)
                  .copyWith(
                    helperText: 'At least 10 characters',
                    helperStyle: const TextStyle(
                      fontSize: 10,
                      color: SFColors.muted,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: SFColors.muted,
                      ),
                    ),
                  ),
              onFieldSubmitted: (_) => submit(),
              validator: (value) =>
                  (value?.length ?? 0) >= 10 && (value?.length ?? 0) <= 128
                  ? null
                  : 'Use 10–128 characters.',
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SFColors.dangerSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: SFColors.danger,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: SFPressable(
                onTap: busy ? null : () {},
                child: FilledButton(
                  onPressed: busy ? null : submit,
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
            const SizedBox(height: 4),
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
            const SizedBox(height: 6),
            Text(
              'Your data stays in the local Smart Finance backend. '
              'Passwords are stored salted & hashed.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: SFColors.faint),
            ),
          ],
        ),
      ),
    );
    if (!wide) return card;
    return Card(child: card);
  }

  InputDecoration _authDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19, color: SFColors.muted),
      );
}

/// Rounded brand mark shown above the mobile sign-in card.
class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: SFColors.brand,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: SFColors.brand.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.auto_awesome, size: 21, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Text.rich(
        TextSpan(
          text: 'smart',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: SFColors.ink,
          ),
          children: [
            TextSpan(
              text: 'finance',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: SFColors.ink.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Deep emerald showcase panel on wide screens, mirroring the web sign-in hero.
class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0E3D33), Color(0xFF0B2C25)],
      ),
    ),
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _HeroGridPainter())),
        Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'smartfinance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Money clarity,\nbeautifully simple.',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                        letterSpacing: -0.8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Record income and expenses in KZT, scan receipts, '
                      'follow your budgets and reach savings goals.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFFB7D5C4),
                      ),
                    ),
                    const SizedBox(height: 34),
                    ...const [
                      _HeroPoint(
                        icon: Icons.receipt_long_outlined,
                        title: 'Receipt scanning',
                        subtitle: 'Snap a receipt, review, save.',
                      ),
                      _HeroPoint(
                        icon: Icons.pie_chart_outline,
                        title: 'Spending insights',
                        subtitle: 'Breakdowns and a transparent forecast.',
                      ),
                      _HeroPoint(
                        icon: Icons.savings_outlined,
                        title: 'Budgets & goals',
                        subtitle: 'Limits that keep spending on track.',
                      ),
                    ],
                    const SizedBox(height: 36),
                    const Text(
                      'Amounts are recorded in Kazakhstani tenge (₸).',
                      style: TextStyle(fontSize: 11, color: Color(0xFF7FA391)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _HeroPoint extends StatelessWidget {
  const _HeroPoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF5FC49C)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9FC4B2)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HeroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.04);
    const step = 72.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroGridPainter oldDelegate) => false;
}
