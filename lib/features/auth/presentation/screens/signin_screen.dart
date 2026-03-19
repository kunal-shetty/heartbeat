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
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradientVertical,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Back button ──────────────────────────────────────────
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

                // ── Hero header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.35), width: 2),
                        ),
                        child: const Icon(Icons.lock_open_rounded,
                            color: Colors.white, size: 38),
                      )
                          .animate()
                          .scale(duration: 500.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome Back!',
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to continue to Heartbeat',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                            ),
                      ).animate().fadeIn(delay: 350.ms),
                    ],
                  ),
                ),

                // ── White card ───────────────────────────────────────────
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoadingState;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
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
                                    margin: const EdgeInsets.only(bottom: 24),
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
                                const SizedBox(height: 4),
                                Text(
                                  'Enter your email and password.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppTheme.neutral400),
                                ).animate().fadeIn(delay: 260.ms),
                                const SizedBox(height: 24),

                                // Email
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
                                )
                                    .animate()
                                    .fadeIn(delay: 300.ms)
                                    .slideX(begin: -0.08, end: 0),
                                const SizedBox(height: 14),

                                // Password
                                AuthTextField(
                                  controller: _passwordController,
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  label: 'Password',
                                  validator: (v) =>
                                      v == null || v.isEmpty
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
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 350.ms)
                                    .slideX(begin: -0.08, end: 0),
                                const SizedBox(height: 10),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => context.showSnackBar(
                                        'Forgot password coming soon!'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: AppTheme.brandPink,
                                    ),
                                    child: const Text('Forgot Password?',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                  ),
                                ).animate().fadeIn(delay: 380.ms),
                                const SizedBox(height: 24),

                                // Gradient sign in button
                                _GradientButton(
                                  label: isLoading ? null : 'Sign In',
                                  onTap: isLoading ? () {} : _signIn,
                                ).animate().fadeIn(delay: 420.ms),
                                const SizedBox(height: 18),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color: AppTheme.neutral100,
                                            thickness: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      child: Text('or',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: AppTheme.neutral400)),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: AppTheme.neutral100,
                                            thickness: 1)),
                                  ],
                                ).animate().fadeIn(delay: 440.ms),
                                const SizedBox(height: 18),

                                // Google button
                                OutlinedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () => context
                                          .read<AuthBloc>()
                                          .add(AuthSignInWithGoogleEvent()),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    side: BorderSide(
                                        color: AppTheme.neutral400
                                            .withOpacity(0.4)),
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
                                ).animate().fadeIn(delay: 470.ms),
                                const SizedBox(height: 28),

                                // Sign up link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppTheme.neutral600),
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
                                              color: AppTheme.brandPink,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(delay: 500.ms),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().slideY(
                      begin: 0.2, end: 0, duration: 400.ms, delay: 100.ms),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String? label;
  final VoidCallback onTap;
  const _GradientButton({this.label, required this.onTap});

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
        child: label == null
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(
                label!,
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
