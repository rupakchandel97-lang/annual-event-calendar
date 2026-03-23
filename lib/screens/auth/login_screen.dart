import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);

    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/');
            });
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenHeight = MediaQuery.of(context).size.height;
                      final heroHeight = (screenHeight * 0.34).clamp(250.0, 360.0);
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: palette.surface.withOpacity(palette.isDark ? 0.9 : 0.8),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: palette.textPrimary.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(32),
                              ),
                              child: Stack(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: heroHeight,
                                    child: Image.asset(
                                      'assets/images/landing_family.jpg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            palette.heroOverlayStart,
                                            palette.heroOverlayEnd,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 22,
                                    right: 22,
                                    bottom: 20,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: palette.chipBackground,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: const Text(
                                            'Keep everyone in sync',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'One shared place for school, travel, birthdays, and family routines.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                height: 1.15,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                              child: Row(
                                children: [
                                  _FeaturePill(
                                    icon: Icons.event_repeat_rounded,
                                    label: 'Trips & multi-day plans',
                                  ),
                                  const SizedBox(width: 12),
                                  _FeaturePill(
                                    icon: Icons.groups_rounded,
                                    label: 'Family invites',
                                    accent: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to manage calendars, travel plans, school nights, and every in-between moment.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                  ),
                  if (authProvider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        authProvider.errorMessage!,
                        style: TextStyle(color: palette.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () {
                              authProvider.signIn(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                              );
                            },
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        if (_emailController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter your email to reset password'),
                            ),
                          );
                          return;
                        }

                        authProvider.resetPassword(_emailController.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset email sent'),
                          ),
                        );
                      },
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface.withOpacity(palette.isDark ? 0.9 : 0.72),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () => context.go('/signup'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool accent;

  const _FeaturePill({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: accent
              ? palette.accent.withOpacity(0.14)
              : palette.surface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: accent ? palette.primary : palette.secondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
