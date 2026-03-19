import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../viewmodels/signup_view_model.dart';
import 'widgets/auth_shell.dart';
import 'widgets/auth_switch_prompt.dart';
import 'widgets/auth_text_field.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  late final SignUpViewModel _viewModel;
  late final AnimationController _intro;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _viewModel = SignUpViewModel();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await _viewModel.signup();
    if (!mounted || !success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign up initialized successfully')),
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
          showBackButton: true,
          onBack: () {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
          child: AnimatedBuilder(
            animation: fade,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 28 * (1 - fade.value)),
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
                  isPhone ? 18 : 28,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AuthHero(
                          eyebrow: 'New bidder registration',
                          title: 'Create your account',
                          subtitle:
                              'Start with a cleaner mobile sign-up journey designed for auctions, tenders, and secure public-sector participation.',
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
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Complete your profile once and continue everything from your phone.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 18),
                              AuthFieldSpacing(
                                child: AuthTextField(
                                  controller: _viewModel.nameController,
                                  label: 'Full name',
                                  icon: Icons.person_outline,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) => Validators.requiredField(
                                    value,
                                    fieldName: 'Name',
                                  ),
                                ),
                              ),
                              AuthFieldSpacing(
                                child: AuthTextField(
                                  controller: _viewModel.nationalIdController,
                                  label: 'National ID',
                                  icon: Icons.badge_outlined,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  validator: Validators.nationalId,
                                ),
                              ),
                              AuthFieldSpacing(
                                child: AuthTextField(
                                  controller: _viewModel.emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: Validators.email,
                                ),
                              ),
                              AuthFieldSpacing(
                                child: AuthTextField(
                                  controller: _viewModel.phoneController,
                                  label: 'Phone',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  validator: Validators.phone,
                                ),
                              ),
                              AuthFieldSpacing(
                                child: AuthTextField(
                                  controller: _viewModel.passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.next,
                                  validator: Validators.strongPassword,
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
                              ),
                              AuthFieldSpacing(
                                child: AuthTextField(
                                  controller:
                                      _viewModel.confirmPasswordController,
                                  label: 'Confirm password',
                                  icon: Icons.lock_reset_outlined,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  validator: (value) =>
                                      Validators.confirmPassword(
                                    value,
                                    _viewModel.passwordController.text.trim(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const AuthInfoBanner(
                                icon: Icons.verified_user_outlined,
                                text:
                                    'Citizen accounts are created with a default role and can be reviewed through the admin workflow later.',
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
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Create account'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              AuthSwitchPrompt(
                                message: 'Already have an account?',
                                actionLabel: 'Sign in',
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.login,
                                  );
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
