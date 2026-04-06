import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
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
    final panelColor = EntryFlowTokens.panel;
    final inputFill = EntryFlowTokens.inputFill;
    final inputBorder = EntryFlowTokens.inputBorder;

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
                          child: _SignupHero(
                            eyebrow: l10n.newBidderRegistration,
                            title: l10n.createYourAccount,
                            subtitle: l10n.signupHeroSubtitle,
                            compact: isPhone,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withOpacity(.08)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.22),
                                blurRadius: 28,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme: InputDecorationTheme(
                                  filled: true,
                                  fillColor: inputFill,
                                  labelStyle: const TextStyle(
                                    color: EntryFlowTokens.textMuted,
                                  ),
                                  prefixIconColor: EntryFlowTokens.textMuted,
                                  suffixIconColor: EntryFlowTokens.textMuted,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: inputBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: EntryFlowTokens.accent,
                                      width: 1.4,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFC25A5A)),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFC25A5A)),
                                  ),
                                ),
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
                                  _LabeledField(
                                    child: TextFormField(
                                      controller: _name,
                                      decoration: InputDecoration(
                                        labelText: l10n.fullName,
                                        prefixIcon: const Icon(Icons.person_outline),
                                      ),
                                      validator: (v) => (v ?? '').trim().isEmpty
                                          ? l10n.nameRequired
                                          : null,
                                    ),
                                  ),
                                  _LabeledField(
                                    child: TextFormField(
                                      controller: _nationalId,
                                      keyboardType: TextInputType.number,
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
                                  _LabeledField(
                                    child: TextFormField(
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
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
                                  _LabeledField(
                                    child: TextFormField(
                                      controller: _phone,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        labelText: l10n.phone,
                                        prefixIcon: const Icon(Icons.phone_outlined),
                                      ),
                                      validator: (v) =>
                                          (v ?? '').trim().isEmpty ? l10n.phoneRequired : null,
                                    ),
                                  ),
                                  _LabeledField(
                                    child: TextFormField(
                                      controller: _pass,
                                      obscureText: _obscure,
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
                                  _LabeledField(
                                    child: TextFormField(
                                      controller: _confirm,
                                      obscureText: _obscure,
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
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF132742),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: inputBorder),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.verified_user_outlined,
                                          color: EntryFlowTokens.accent,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            l10n.citizenAccountNote,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: EntryFlowTokens.textMuted,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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

class _LabeledField extends StatelessWidget {
  final Widget child;

  const _LabeledField({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: child,
    );
  }
}

class _SignupHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final bool compact;

  const _SignupHero({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x1FFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(.08)),
          ),
          child: Text(
            eyebrow,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: .3,
            ),
          ),
        ),
        SizedBox(height: compact ? 14 : 18),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 34 : 40,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            color: EntryFlowTokens.textMuted,
            fontSize: compact ? 14 : 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
