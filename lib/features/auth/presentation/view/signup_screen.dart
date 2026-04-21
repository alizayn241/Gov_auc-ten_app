import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:gov_auction_app/features/auth/presentation/widgets/auth_form_theme.dart';
import 'package:gov_auction_app/features/auth/presentation/widgets/auth_ui.dart';
import 'package:gov_auction_app/features/onboarding/presentation/widgets/entry_background.dart';

import '../../../../core/localization/app_localizations.dart';
import '../viewmodel/auth_view_model.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _nationalId = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  late final AnimationController _intro;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _name.dispose();
    _nationalId.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authViewModelProvider);
    final vm = ref.read(authViewModelProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final isPhone = size.width < 600;
    ref.listen(authViewModelProvider, (prev, next) {
      if (next.isAuthenticated && next.isInitialized) {
        context.go('/home');
      }
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    final fade = CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutCubic,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: EntryBackground(child: SizedBox.expand()),
          ),
          const SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: AppPageBackButton(
                  fallbackRoute: '/login',
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0x24FFFFFF),
                ),
              ),
            ),
          ),
          SafeArea(
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
                            eyebrow: l10n.newBidderRegistration,
                            title: l10n.createYourAccount,
                            subtitle: l10n.signupHeroSubtitle,
                            compact: isPhone,
                          ),
                        ),
                        const SizedBox(height: 18),
                        AuthPanel(
                          child: Theme(
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme: AuthFormTheme.inputDecorationTheme(),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.createAccount,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.createAccountSubtitle,
                                    style: const TextStyle(
                                      color: EntryFlowTokens.textMuted,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  AuthFieldSpacing(
                                    child: TextFormField(
                                      controller: _name,
                                      style: AuthFormTheme.inputTextStyle,
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                        labelText: l10n.fullName,
                                        prefixIcon: const Icon(Icons.person_outline),
                                      ),
                                      validator: (v) => (v ?? '').trim().isEmpty
                                          ? l10n.nameRequired
                                          : null,
                                    ),
                                  ),
                                  AuthFieldSpacing(
                                    child: TextFormField(
                                      controller: _nationalId,
                                      keyboardType: TextInputType.number,
                                      style: AuthFormTheme.inputTextStyle,
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                        labelText: l10n.nationalId,
                                        prefixIcon: const Icon(Icons.badge_outlined),
                                      ),
                                      validator: (v) {
                                        final value = (v ?? '').trim();
                                        if (value.isEmpty) return l10n.nationalIdRequired;
                                        if (value.length < 10) return l10n.invalidIdLength;
                                        return null;
                                      },
                                    ),
                                  ),
                                  AuthFieldSpacing(
                                    child: TextFormField(
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
                                      style: AuthFormTheme.inputTextStyle,
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                        labelText: l10n.email,
                                        prefixIcon: const Icon(Icons.email_outlined),
                                      ),
                                      validator: (v) {
                                        final value = (v ?? '').trim();
                                        if (value.isEmpty) return l10n.emailRequired;
                                        if (!value.contains('@')) return l10n.invalidEmail;
                                        return null;
                                      },
                                    ),
                                  ),
                                  AuthFieldSpacing(
                                    child: TextFormField(
                                      controller: _phone,
                                      keyboardType: TextInputType.phone,
                                      style: AuthFormTheme.inputTextStyle,
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                        labelText: l10n.phone,
                                        prefixIcon: const Icon(Icons.phone_outlined),
                                      ),
                                      validator: (v) =>
                                          (v ?? '').trim().isEmpty ? l10n.phoneRequired : null,
                                    ),
                                  ),
                                  AuthFieldSpacing(
                                    child: TextFormField(
                                      controller: _pass,
                                      obscureText: _obscure,
                                      style: AuthFormTheme.inputTextStyle,
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                        labelText: l10n.password,
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => _obscure = !_obscure),
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                      validator: (v) {
                                        final value = (v ?? '').trim();
                                        if (value.isEmpty) return l10n.passwordRequired;
                                        if (value.length < 8) return l10n.minimum8Characters;
                                        final hasNum = RegExp(r'\d').hasMatch(value);
                                        if (!hasNum) return l10n.includeOneNumber;
                                        return null;
                                      },
                                    ),
                                  ),
                                  AuthFieldSpacing(
                                    child: TextFormField(
                                      controller: _confirm,
                                      obscureText: _obscure,
                                      style: AuthFormTheme.inputTextStyle,
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                        labelText: l10n.confirmPassword,
                                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                                      ),
                                      validator: (v) {
                                        final value = (v ?? '').trim();
                                        if (value != _pass.text.trim()) {
                                          return l10n.passwordsDoNotMatch;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  AuthInfoCard(
                                    icon: Icons.verified_user_outlined,
                                    message: l10n.citizenAccountNote,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: state.isLoading
                                          ? null
                                          : () async {
                                              if (!_formKey.currentState!.validate()) return;

                                              final created = await vm.doSignup(
                                                name: _name.text.trim(),
                                                nationalId: _nationalId.text.trim(),
                                                email: _email.text.trim(),
                                                phone: _phone.text.trim(),
                                                password: _pass.text.trim(),
                                              );

                                              if (!mounted || !created) return;
                                              context.go('/login');
                                            },
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size.fromHeight(54),
                                        backgroundColor: EntryFlowTokens.accent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: state.isLoading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : Text(l10n.createAccount),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${l10n.alreadyHaveAccount} ',
                                        style: const TextStyle(color: EntryFlowTokens.textMuted),
                                      ),
                                      TextButton(
                                        onPressed: () => context.go('/login'),
                                        child: Text(
                                          l10n.signIn,
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
