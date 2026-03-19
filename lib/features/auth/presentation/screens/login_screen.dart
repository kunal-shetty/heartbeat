import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../blocs/auth_bloc.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSentState) {
          context.push(AppRoutes.otp, extra: state.phone);
        } else if (state is AuthAuthenticatedState) {
          context.go(AppRoutes.chatList);
        } else if (state is AuthNewUserState) {
          context.push(AppRoutes.register, extra: state);
        } else if (state is AuthErrorState) {
          context.showSnackBar(state.message, isError: true);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradientVertical,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Hero Section ─────────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Glowing app icon
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brandPink.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: AppTheme.brandPink,
                            size: 52,
                          ),
                        )
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.elasticOut)
                            .fadeIn(duration: 300.ms),
                        const SizedBox(height: 28),
                        Text(
                          'Heartbeat',
                          style:
                              Theme.of(context).textTheme.displayLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 38,
                                    letterSpacing: -1,
                                  ),
                        )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 400.ms)
                            .slideY(begin: 0.3, end: 0),
                        const SizedBox(height: 10),
                        Text(
                          'Stay connected with the people\nthat matter most.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    height: 1.5,
                                  ),
                        ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                        const SizedBox(height: 24),

                        // Feature pills
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FeaturePill(
                                icon: Icons.lock_outline, label: 'Private'),
                            const SizedBox(width: 10),
                            _FeaturePill(
                                icon: Icons.bolt_rounded, label: 'Fast'),
                            const SizedBox(width: 10),
                            _FeaturePill(
                                icon: Icons.people_outline, label: 'Groups'),
                          ],
                        ).animate().fadeIn(delay: 550.ms),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Card ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.neutral100,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Get Started',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in or create a new account.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.neutral400,
                            ),
                      ).animate().fadeIn(delay: 360.ms),
                      const SizedBox(height: 22),

                      // Sign In button — gradient
                      _GradientButton(
                        label: 'Sign In',
                        onTap: () => context.push(AppRoutes.signIn),
                      ).animate().fadeIn(delay: 420.ms).scale(
                          delay: 420.ms,
                          duration: 300.ms,
                          curve: Curves.easeOut),
                      const SizedBox(height: 12),

                      // Create Account button
                      OutlinedButton(
                        onPressed: () => context.push(AppRoutes.register),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(
                              color: AppTheme.brandPink, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: AppTheme.brandPink,
                        ),
                        child: Text(
                          'Create Account',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppTheme.brandPink,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ).animate().fadeIn(delay: 480.ms),
                      const SizedBox(height: 12),

                      // Google sign in
                      OutlinedButton.icon(
                        onPressed: () => context
                            .read<AuthBloc>()
                            .add(AuthSignInWithGoogleEvent()),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(
                              color: AppTheme.neutral400.withOpacity(0.35)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.g_mobiledata,
                            size: 28, color: AppTheme.brandOrange),
                        label: Text(
                          'Continue with Google',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: AppTheme.neutral800),
                        ),
                      ).animate().fadeIn(delay: 520.ms),
                    ],
                  ),
                ).animate().slideY(
                    begin: 0.25, end: 0, duration: 450.ms, delay: 100.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandPink.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
        ),
      ),
    );
  }
}
