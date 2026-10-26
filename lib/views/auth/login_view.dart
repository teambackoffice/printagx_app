import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/viewmodels/auth_view_model.dart';
import 'package:printagx_app/views/shell/app_shell.dart';
import 'package:printagx_app/views/widgets/common.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _submitted = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    final auth = context.read<AuthViewModel>();
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;

    if (success) {
      TextInput.finishAutofillContext();
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: AppDurations.slow,
          pageBuilder: (_, _, _) => const AppShell(),
          transitionsBuilder: (_, a, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
            child: child,
          ),
        ),
      );
    } else {
      showAppSnack(context, auth.error ?? 'Sign in failed', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((AuthViewModel vm) => vm.isLoading);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Header(),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.xxl,
                        AppSpace.xxxl,
                        AppSpace.xxl,
                        AppSpace.xxl,
                      ),
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: _buildForm(isLoading),
                      ),
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

  Widget _buildForm(bool isLoading) {
    final p = context.palette;
    return Form(
      key: _formKey,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome back', style: context.text.headlineMedium),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Sign in to Screen Arts to continue',
              style: context.text.bodyLarge?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpace.xxxl),
            const _FieldLabel('Email or username'),
            TextFormField(
              controller: _usernameController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              autocorrect: false,
              style: context.text.bodyLarge,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter your email or username'
                  : null,
              decoration: const InputDecoration(
                hintText: 'you@company.com',
                prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            const _FieldLabel('Password'),
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              style: context.text.bodyLarge,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                if (v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: AnimatedSwitcher(
                    duration: AppDurations.fast,
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      key: ValueKey(_obscurePassword),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xxxl),
            AppButton(
              label: 'Sign in',
              icon: Icons.arrow_forward_rounded,
              loading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpace.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: AppIconSize.sm,
                  color: p.textMuted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Trouble signing in? Contact your admin.',
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ink header with the wordmark and a halftone texture.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1B20), Color(0xFF2C2C34)],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl + 4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            right: 0,
            width: 260,
            height: 220,
            child: Halftone(opacity: 0.1),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.xxl,
              top + AppSpace.xxxl,
              AppSpace.xxl,
              AppSpace.xxxl + AppSpace.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpace.xxxl),
                Text(
                  'PRODUCTION WORKSPACE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                const Text(
                  'Track every job,\nevery minute.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: AppSpace.sm),
      child: Text(
        text,
        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
