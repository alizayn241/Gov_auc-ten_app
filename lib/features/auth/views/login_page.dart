import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../viewmodels/login_view_model.dart';
import 'widgets/auth_shell.dart';
import 'widgets/auth_switch_prompt.dart';
import 'widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final LoginViewModel _viewModel;
  late final AnimationController _intro;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await _viewModel.login();
    if (!mounted || !success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login initialized successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isPhone = size.width < 600;
    final fade = CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutCubic,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_viewModel, _intro]),
      builder: (context, _) {
        return AuthShell(
          child: AnimatedBuilder(
            animation: fade,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 24 * (1 - fade.value)),
                child: Opacity(
                  opacity: fade.value,
                  child: child,
                ),
              );
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  isPhone ? 24 : 36,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AuthHero(
                          eyebrow: 'Government Auction Portal',
                          title: 'Welcome back',
                          subtitle:
                              'Track bids, manage watchlists, and continue participating from your phone with a faster, cleaner sign-in flow.',
                          compact: isPhone,
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthCard(
                        child: Form(
                          key: _viewModel.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Use your account to continue to auctions, tenders, and saved activity.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 18),
                              AuthTextField(
                                controller: _viewModel.emailController,
                                label: 'Email address',
                                icon: Icons.alternate_email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: Validators.email,
                              ),
                              const SizedBox(height: 12),
                              AuthTextField(
                                controller: _viewModel.passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                validator: Validators.password,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() => _obscure = !_obscure);
                                  },
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const AuthInfoBanner(
                                icon: Icons.shield_outlined,
                                text:
                                    'Secure sign-in keeps your auction activity and tender access synced across sessions.',
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _viewModel.isLoading ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: _viewModel.isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Continue'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              AuthSwitchPrompt(
                                message: 'Need an account?',
                                actionLabel: 'Create one',
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.signup);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
