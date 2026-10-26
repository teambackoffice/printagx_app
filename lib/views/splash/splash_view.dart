import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/viewmodels/auth_view_model.dart';
import 'package:printagx_app/views/auth/login_view.dart';
import 'package:printagx_app/views/shell/app_shell.dart';
import 'package:printagx_app/views/widgets/common.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  // The logo "feeds" up like a sheet leaving a printer, then settles.
  late final Animation<double> _sheet = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0, 0.45, curve: Curves.easeOut),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.45, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final auth = context.read<AuthViewModel>();
    await Future.wait([
      auth.restoreSession(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) =>
            auth.isLoggedIn ? const AppShell() : const LoginView(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppBrand.ink,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              top: 0,
              right: 0,
              width: 320,
              height: 320,
              child: Halftone(opacity: 0.07),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  FadeTransition(
                    opacity: _fade,
                    child: AnimatedBuilder(
                      animation: _sheet,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, 40 * (1 - _sheet.value)),
                        child: Transform.rotate(
                          angle: -0.05 * (1 - _sheet.value),
                          child: child,
                        ),
                      ),
                      child: const Text(
                        'Printagx',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xxl),
                  FadeTransition(
                    opacity: _tagline,
                    child: Text(
                      'PRODUCTION WORKSPACE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const Spacer(flex: 6),
                  FadeTransition(
                    opacity: _tagline,
                    child: SizedBox(
                      width: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: AppBrand.red,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
