import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account/account_activation_stepper.dart';
import 'account/account_app_bar.dart';
import 'account/account_fields.dart';
import 'account/account_hero.dart';
import 'account/account_profile.dart';
import 'account/account_shared.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  late Future<AccountProfile?> _profileFuture;
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  AccountProfile? _profile;

  late final AnimationController _animCtrl;
  late final Animation<double> _heroAnim;
  late final Animation<double> _bodyAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _heroAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _bodyAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
    _profileFuture = _loadAndInit();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _displayNameCtrl.dispose();
    _phoneCtrl.dispose();
    _nationalIdCtrl.dispose();
    super.dispose();
  }

  Future<AccountProfile?> _loadAndInit() async {
    final profile = await _loadProfile();
    if (profile != null) _initControllers(profile);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animCtrl.forward(from: 0);
    });
    return profile;
  }

  Future<AccountProfile?> _loadProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    final row = await client
        .from('profiles')
        .select('display_name,national_id,phone,role,account_type,kyc_status')
        .eq('id', user.id)
        .maybeSingle();

    return AccountProfile(
      email: user.email ?? '',
      displayName:
          (row?['display_name'] ?? user.userMetadata?['name'] ?? '') as String,
      nationalId: (row?['national_id'] ?? '') as String,
      phone: (row?['phone'] ?? user.userMetadata?['phone'] ?? '') as String,
      role: (row?['role'] ?? 'citizen') as String,
      accountType: (row?['account_type'] ?? 'individual') as String,
      status: (row?['kyc_status'] ?? 'pending') as String,
    );
  }

  void _initControllers(AccountProfile profile) {
    _profile = profile;
    _displayNameCtrl.text = profile.displayName;
    _phoneCtrl.text = profile.phone;
    _nationalIdCtrl.text = profile.nationalId;
  }

  Future<void> _refresh() async {
    setState(() {
      _isEditing = false;
      _profileFuture = _loadAndInit();
    });
    await _profileFuture;
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      if (_profile != null) {
        _initControllers(_profile!);
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'display_name': _displayNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'national_id': _nationalIdCtrl.text.trim(),
      }, onConflict: 'id');

      if (!mounted) return;
      await _refresh();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Profile updated successfully',
              'تم تحديث الملف الشخصي بنجاح',
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      setState(() => _isEditing = false);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: FutureBuilder<AccountProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AccountLoadingState();
          }

          if (snapshot.hasError) {
            return AccountFeedbackState(
              icon: Icons.error_outline_rounded,
              title: context.tr('Could not load account', 'تعذر تحميل الحساب'),
              subtitle: context.tr(
                'Please try again in a moment.',
                'يرجى المحاولة مرة أخرى.',
              ),
              actionLabel: context.tr('Retry', 'إعادة المحاولة'),
              onPressed: _refresh,
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return AccountFeedbackState(
              icon: Icons.lock_person_rounded,
              title: context.tr(
                'Sign in to view your account',
                'سجل الدخول لعرض حسابك',
              ),
              subtitle: context.tr(
                'Account details appear here after login.',
                'ستظهر تفاصيل الحساب هنا بعد تسجيل الدخول.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: AccountAppBar(
                    isEditing: _isEditing,
                    isSaving: _isSaving,
                    hasProfile: true,
                    onEdit: () => setState(() => _isEditing = true),
                    onCancel: _cancelEditing,
                    onSave: _saveProfile,
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _heroAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.14),
                        end: Offset.zero,
                      ).animate(_heroAnim),
                      child: AccountHero(
                        profile: profile,
                        displayName:
                            _isEditing ? _displayNameCtrl.text : profile.displayName,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _bodyAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const AccountSectionLabel(label: 'Profile details'),
                              const Spacer(),
                              if (!_isEditing)
                                AccountEditButton(
                                  label: context.tr('Edit', 'تعديل'),
                                  onTap: () => setState(() => _isEditing = true),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: _isEditing
                                ? AccountEditForm(
                                    key: const ValueKey('edit'),
                                    formKey: _formKey,
                                    displayNameCtrl: _displayNameCtrl,
                                    phoneCtrl: _phoneCtrl,
                                    nationalIdCtrl: _nationalIdCtrl,
                                    email: profile.email,
                                    isSaving: _isSaving,
                                    onCancel: _cancelEditing,
                                    onSave: _saveProfile,
                                  )
                                : AccountViewFields(
                                    key: const ValueKey('view'),
                                    profile: profile,
                                  ),
                          ),
                          const SizedBox(height: 20),
                          AccountSectionLabel(
                            label:
                                context.tr('Activation status', 'حالة التفعيل'),
                          ),
                          const SizedBox(height: 10),
                          AccountActivationStepper(profile: profile),
                          const SizedBox(height: 20),
                          AccountInfoBanner(
                            text: context.tr(
                              'Forsa is a secure government platform. All bids are verified and legally binding.',
                              'فرصة منصة حكومية آمنة. جميع العروض موثقة وملزمة قانونيا.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
