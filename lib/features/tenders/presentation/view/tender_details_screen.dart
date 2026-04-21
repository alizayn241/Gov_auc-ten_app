import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:gov_auction_app/features/auth/presentation/viewmodel/auth_view_model.dart';
import 'package:gov_auction_app/features/tenders/data/models/tender_participation.dart';

import '../viewmodel/tender_details_view_model.dart';

class TenderDetailsScreen extends ConsumerStatefulWidget {
  final String tenderId;
  const TenderDetailsScreen({super.key, required this.tenderId});

  @override
  ConsumerState<TenderDetailsScreen> createState() => _TenderDetailsScreenState();
}

class _TenderDetailsScreenState extends ConsumerState<TenderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tenderDetailsViewModelProvider(widget.tenderId).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(tenderDetailsViewModelProvider(widget.tenderId));
    final auth = ref.watch(authViewModelProvider);
    final deadlinePassed =
        st.tender != null && !st.tender!.submissionDeadline.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        leading: const AppPageBackButton(fallbackRoute: '/tenders'),
        title: Text(context.tr('Tender Details', 'تفاصيل المناقصة')),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(tenderDetailsViewModelProvider(widget.tenderId).notifier)
                .load(),
          ),
        ],
      ),
      body: st.loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : st.tender == null
              ? Center(
                  child: Text(
                    st.error ?? context.tr('Tender not found', 'المناقصة غير موجودة'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _TenderOverviewCard(
                      title: st.tender!.title,
                      reference: st.tender!.referenceNo ?? '-',
                      entity: st.tender!.entity ?? '-',
                      status: st.tender!.status,
                      deadline: st.tender!.submissionDeadline,
                    ),
                    const SizedBox(height: 14),
                    _ActionInfoCard(
                      isAuthenticated: auth.isAuthenticated,
                      participation: st.participation,
                      isAdmin: auth.isAdmin,
                      deadlinePassed: deadlinePassed,
                    ),
                    const SizedBox(height: 14),
                    if (deadlinePassed) ...[
                      _InlineMessage(
                        message: context.tr(
                          'Participation is closed because the submission deadline has passed.',
                          'تم إغلاق المشاركة لأن آخر موعد للتقديم قد انتهى.',
                        ),
                        accent: const Color(0xFFB3261E),
                        icon: Icons.lock_clock_outlined,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (st.error != null && st.error!.isNotEmpty) ...[
                      _InlineMessage(
                        message: st.error!,
                        accent: const Color(0xFFB3261E),
                        icon: Icons.error_outline,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (!auth.isAuthenticated) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.login),
                          label: Text(context.tr('Login to Participate', 'سجل الدخول للمشاركة')),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else if (!auth.isAdmin &&
                        st.participation == null &&
                        !deadlinePassed) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: st.applying
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(
                                          tenderDetailsViewModelProvider(
                                            widget.tenderId,
                                          ).notifier,
                                        )
                                        .applyToTender();

                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          context.tr(
                                            'Your participation request has been submitted for review.',
                                            'تم إرسال طلب المشاركة للمراجعة.',
                                          ),
                                        ),
                                      ),
                                    );
                                  } catch (_) {}
                                },
                          icon: st.applying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.how_to_reg_outlined),
                          label: Text(context.tr('Apply to Participate', 'طلب المشاركة')),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.go('/tender/${st.tender!.id}/ranking'),
                        icon: const Icon(Icons.leaderboard_outlined),
                        label: Text(context.tr('Lowest Offers Ranking', 'ترتيب أقل العروض')),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: auth.isAdmin ||
                                !(st.participation?.eligible ?? false) ||
                                deadlinePassed
                            ? null
                            : () => context.go('/tender/${st.tender!.id}/submit'),
                        icon: const Icon(Icons.upload_file),
                        label: Text(context.tr('Submit Lowest Price Offer', 'تقديم أقل عرض سعر')),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _TenderOverviewCard extends StatelessWidget {
  final String title;
  final String reference;
  final String entity;
  final String status;
  final DateTime deadline;

  const _TenderOverviewCard({
    required this.title,
    required this.reference,
    required this.entity,
    required this.status,
    required this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B3C8C), Color(0xFF0A2F6E)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _TenderInfoLine(
            icon: Icons.tag_outlined,
            text: context.tr('Reference: $reference', 'المرجع: $reference'),
          ),
          const SizedBox(height: 8),
          _TenderInfoLine(
            icon: Icons.account_balance_outlined,
            text: context.tr('Entity: $entity', 'الجهة: $entity'),
          ),
          const SizedBox(height: 8),
          _TenderInfoLine(
            icon: Icons.schedule_outlined,
            text: context.tr(
              'Submission deadline: ${deadline.toLocal()}',
              'آخر موعد للتقديم: ${deadline.toLocal()}',
            ),
          ),
        ],
      ),
    );
  }
}

class _TenderInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TenderInfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionInfoCard extends StatelessWidget {
  final bool isAuthenticated;
  final bool isAdmin;
  final bool deadlinePassed;
  final TenderParticipation? participation;

  const _ActionInfoCard({
    required this.isAuthenticated,
    required this.participation,
    required this.isAdmin,
    required this.deadlinePassed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasParticipation = participation != null;
    final eligible = participation?.eligible == true;
    final status = (participation?.status ?? '').toString().toLowerCase();
    final subtitle = deadlinePassed
        ? 'The submission deadline has passed. New participation requests and lowest-price offers are no longer accepted for this tender.'
        : isAdmin
        ? 'Admin accounts can review tender activity, but cannot submit vendor proposals.'
        : !isAuthenticated
            ? 'Sign in first, then request participation before submitting your lowest price offer.'
            : !hasParticipation
                ? 'Request participation first. After admin approval marks you eligible, you can submit your lowest price offer.'
                : eligible
                    ? 'Your participation is approved. You can review ranking or continue directly to submit your lowest price offer.'
                    : status == 'rejected'
                        ? 'Your participation request was not approved. Please contact the tender administrator for more details.'
                        : 'Your participation request is under review. You can check back after the admin team updates your eligibility.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Next steps', 'الخطوات التالية'),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String message;
  final Color accent;
  final IconData icon;

  const _InlineMessage({
    required this.message,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
