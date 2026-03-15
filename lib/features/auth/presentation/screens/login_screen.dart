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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
              // Hero header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: Column(
                  children: [
                    const Icon(Icons.chat_bubble_rounded,
                        color: Colors.white, size: 56)
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text('Chatter',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 6),
                    Text('Connect. Chat. Share.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white.withOpacity(0.85)))
                        .animate()
                        .fadeIn(delay: 350.ms),
                  ],
                ),
              ),

              // Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.neutral100,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.brandPrimary,
                        unselectedLabelColor: AppTheme.neutral400,
                        indicatorColor: AppTheme.brandPrimary,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        tabs: const [
                          Tab(text: 'Phone'),
                          Tab(text: 'Email'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _PhoneTab(controller: _phoneController),
                            _EmailTab(
                              emailController: _emailController,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              onToggleObscure: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                          context.showSnackBar('Enter a valid phone number', isError: true);
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
              const SizedBox(height: 20),
              _GoogleButton(),
            ],
          ),
        );
      },
    );
  }
}

class _EmailTab extends StatelessWidget {
  final TextEditingController emailController, passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;

  const _EmailTab({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
  });

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
              AuthTextField(
                controller: emailController,
                hint: 'you@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                label: 'Email',
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: passwordController,
                hint: '••••••••',
                prefixIcon: Icons.lock_outline,
                obscureText: obscurePassword,
                label: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.neutral400,
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => context.read<AuthBloc>().add(
                          AuthSignInWithEmailEvent(
                            email: emailController.text.trim(),
                            password: passwordController.text,
                          ),
                        ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Sign In'),
              ),
              const SizedBox(height: 20),
              _GoogleButton(),
            ],
          ),
        );
      },
    );
  }
}

class _GoogleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () =>
          context.read<AuthBloc>().add(AuthSignInWithGoogleEvent()),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(color: AppTheme.neutral400.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.g_mobiledata, size: 24, color: AppTheme.brandAccent),
      label: Text('Continue with Google',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: AppTheme.neutral800)),
    );
  }
}
