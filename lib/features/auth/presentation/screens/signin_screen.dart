import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../blocs/auth_bloc.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../widgets/auth_text_field.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthSignInWithEmailEvent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticatedState) {
          context.go(AppRoutes.chatList);
        } else if (state is AuthErrorState) {
          context.showSnackBar(state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.brandPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // ── Back button ──────────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 22),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),

              // ── Hero header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_open_rounded,
                          color: Colors.white, size: 40),
                    )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome Back!',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to continue to Heartbeat',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                    ).animate().fadeIn(delay: 350.ms),
                  ],
                ),
              ),

              // ── White card ───────────────────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoadingState;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                        child: Form(
                          key: _formKey,
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
                                'Sign In',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ).animate().fadeIn(delay: 200.ms),
                              const SizedBox(height: 6),
                              Text(
                                'Enter your email and password to access your account.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.neutral400),
                              ).animate().fadeIn(delay: 280.ms),
                              const SizedBox(height: 28),

                              // Email field
                              AuthTextField(
                                controller: _emailController,
                                hint: 'you@example.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                label: 'Email',
                                validator: (v) =>
                                    v == null || !v.trim().isValidEmail
                                        ? 'Enter a valid email'
                                        : null,
                              ).animate().fadeIn(delay: 320.ms).slideX(begin: -0.1, end: 0),
                              const SizedBox(height: 16),

                              // Password field
                              AuthTextField(
                                controller: _passwordController,
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                label: 'Password',
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Password is required'
                                    : null,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.neutral400,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ).animate().fadeIn(delay: 380.ms).slideX(begin: -0.1, end: 0),
                              const SizedBox(height: 12),

                              // Forgot password (future)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    context.showSnackBar(
                                        'Forgot password coming soon!');
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.brandPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 400.ms),
                              const SizedBox(height: 28),

                              // Sign In button
                              ElevatedButton(
                                onPressed: isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Sign In'),
                              ).animate().fadeIn(delay: 440.ms).scale(
                                  delay: 440.ms,
                                  duration: 300.ms,
                                  curve: Curves.easeOut),
                              const SizedBox(height: 20),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: AppTheme.neutral100,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'or',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppTheme.neutral400),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: AppTheme.neutral100,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 460.ms),
                              const SizedBox(height: 20),

                              // Google button
                              OutlinedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () => context
                                        .read<AuthBloc>()
                                        .add(AuthSignInWithGoogleEvent()),
                                style: OutlinedButton.styleFrom(
                                  minimumSize:
                                      const Size(double.infinity, 52),
                                  side: BorderSide(
                                      color: AppTheme.neutral400
                                          .withOpacity(0.4)),
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
                              ).animate().fadeIn(delay: 500.ms),
                              const SizedBox(height: 32),

                              // Don't have account
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: AppTheme.neutral600,
                                            ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        context.push(AppRoutes.register),
                                    child: Text(
                                      'Create one',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.brandPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 520.ms),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 100.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
