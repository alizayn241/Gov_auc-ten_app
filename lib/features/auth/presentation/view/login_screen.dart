import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';
import 'package:gov_auction_app/features/auth/presentation/widgets/auth_form_theme.dart';
import 'package:gov_auction_app/features/auth/presentation/widgets/auth_ui.dart';
import 'package:gov_auction_app/features/onboarding/presentation/widgets/entry_background.dart';

import '../../../../core/localization/app_localizations.dart';
import '../viewmodel/auth_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _intro;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vm = ref.read(authViewModelProvider.notifier);
    await vm.doLogin(
      email: _email.text.trim(),
      password: _password.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authViewModelProvider);
    final size = MediaQuery.sizeOf(context);
    final isPhone = size.width < 600;
    final fade = CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutCubic,
    );

    ref.listen(authViewModelProvider, (prev, next) {
      if (next.isAuthenticated && prev?.isAuthenticated != true) {
        context.go('/home');
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: EntryBackground(child: SizedBox.expand()),
          ),
          SafeArea(
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
                            eyebrow: l10n.governmentAuctionPortal,
                            title: l10n.welcomeBack,
                            subtitle: l10n.loginHeroSubtitle,
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
                                    l10n.signIn,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.signInSubtitle,
                                    style: const TextStyle(
                                      color: EntryFlowTokens.textMuted,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    style: AuthFormTheme.inputTextStyle,
                                    cursorColor: Colors.white,
                                    decoration: InputDecoration(
                                      labelText: l10n.emailAddress,
                                      prefixIcon: const Icon(Icons.alternate_email),
                                    ),
                                    validator: (v) {
                                      final x = (v ?? '').trim();
                                      if (x.isEmpty) return l10n.emailRequired;
                                      if (!x.contains('@')) return l10n.enterValidEmail;
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _password,
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
                                      if ((v ?? '').trim().isEmpty) {
                                        return l10n.passwordRequired;
                                      }
                                      if ((v ?? '').trim().length < 6) {
                                        return l10n.min6Chars;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  if (state.error != null &&
                                      state.error!.isNotEmpty) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0x66241C2A),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0x887D4151),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Color(0xFFE8AAB3),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              state.error!,
                                              style: const TextStyle(
                                                color: Color(0xFFFFD8DE),
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  AuthInfoCard(
                                    icon: Icons.shield_outlined,
                                    message: l10n.secureSignInNote,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: state.isLoading ? null : _submit,
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
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(l10n.continueText),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${l10n.needAccount} ',
                                        style: const TextStyle(color: EntryFlowTokens.textMuted),
                                      ),
                                      TextButton(
                                        onPressed: () => context.go('/signup'),
                                        child: Text(
                                          l10n.createOne,
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
