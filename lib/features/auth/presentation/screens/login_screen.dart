import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../blocs/auth_bloc.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

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
        backgroundColor: AppTheme.brandPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // ── Hero Section ─────────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppTheme.brandPrimary,
                          size: 52,
                        ),
                      )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.elasticOut)
                          .fadeIn(duration: 300.ms),
                      const SizedBox(height: 28),
                      Text(
                        'Heartbeat',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              height: 1.5,
                            ),
                      ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),

              // ── Bottom Card ──────────────────────────────────────────────
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 28),
                          decoration: BoxDecoration(
                            color: AppTheme.neutral100,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      Text(
                        'Get Started',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to your account or create a new one.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.neutral400,
                            ),
                      ).animate().fadeIn(delay: 360.ms),
                      const SizedBox(height: 28),

                      // Sign In button
                      ElevatedButton(
                        onPressed: () => context.push(AppRoutes.signIn),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Sign In'),
                      ).animate().fadeIn(delay: 420.ms).scale(
                          delay: 420.ms,
                          duration: 300.ms,
                          curve: Curves.easeOut),
                      const SizedBox(height: 14),

                      // Create Account button
                      OutlinedButton(
                        onPressed: () => context.push(AppRoutes.register),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          side: const BorderSide(
                              color: AppTheme.brandPrimary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: AppTheme.brandPrimary,
                        ),
                        child: Text(
                          'Create Account',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppTheme.brandPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ).animate().fadeIn(delay: 480.ms),
                      const SizedBox(height: 20),

                      // Google sign in
                      OutlinedButton.icon(
                        onPressed: () {
                          context
                              .read<AuthBloc>()
                              .add(AuthSignInWithGoogleEvent());
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          side: BorderSide(
                              color: AppTheme.neutral400.withOpacity(0.35)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.g_mobiledata,
                            size: 28, color: AppTheme.brandAccent),
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
                ).animate().slideY(begin: 0.25, end: 0, duration: 450.ms, delay: 100.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phone-based OTP tab – kept for re-use if extended later
class _PhoneTab extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoadingState;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text('Enter your phone number',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('We\'ll send you a verification code.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.neutral400)),
              const SizedBox(height: 24),
              AuthTextField(
                controller: controller,
                hint: '+91 98765 43210',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                label: 'Phone number',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (controller.text.isValidPhone) {
                          context.read<AuthBloc>().add(
                              AuthSignInWithPhoneEvent(controller.text.trim()));
                        } else {
                          context.showSnackBar('Enter a valid phone number',
                              isError: true);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Send OTP'),
              ),
            ],
          ),
        );
      },
    );
  }
}
