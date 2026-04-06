import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';

import '../viewmodel/tenders_view_model.dart';

class SubmitProposalScreen extends ConsumerStatefulWidget {
  final String tenderId;
  const SubmitProposalScreen({super.key, required this.tenderId});

  @override
  ConsumerState<SubmitProposalScreen> createState() =>
      _SubmitProposalScreenState();
}

class _SubmitProposalScreenState
    extends ConsumerState<SubmitProposalScreen> {
  final _amount = TextEditingController();
  bool loading = false;
  bool loadingLowest = true;
  String? msg;
  num? currentLowest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLowest();
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  num? _parseAmount() {
    final raw = _amount.text.trim();
    if (raw.isEmpty) return null;
    return num.tryParse(raw);
  }

  Future<void> _loadCurrentLowest() async {
    setState(() {
      loadingLowest = true;
    });

    try {
      final ranking =
          await ref.read(tendersRepositoryProvider).getTenderRanking(
                widget.tenderId,
              );
      if (!mounted) return;
      setState(() {
        currentLowest = ranking.isEmpty ? null : ranking.first.financialTotal;
        loadingLowest = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        currentLowest = null;
        loadingLowest = false;
      });
    }
  }

  Future<void> _submit() async {
    final value = _parseAmount();
    if (value == null) {
      _toast(context.tr('Please enter a valid number', 'يرجى إدخال رقم صحيح'));
      return;
    }
    if (value <= 0) {
      _toast(context.tr('Amount must be greater than 0', 'يجب أن يكون المبلغ أكبر من 0'));
      return;
    }
    if (currentLowest != null && value >= currentLowest!) {
      final error =
          context.tr(
            'Your offer must be lower than the current lowest price of EGP ${currentLowest!.toStringAsFixed(0)}.',
            'يجب أن يكون عرضك أقل من أقل سعر حالي وهو ${context.l10n.t('EGP', 'ج.م')} ${currentLowest!.toStringAsFixed(0)}.',
          );
      setState(() {
        msg = error;
      });
      _toast(error);
      return;
    }

    setState(() {
      loading = true;
      msg = null;
    });

    try {
      final proposalId = await ref.read(tendersRepositoryProvider).submitProposal(
            tenderId: widget.tenderId,
            financialTotal: value,
            currency: 'EGP',
          );

      if (!mounted) return;

      _toast(
        context.tr(
          'Proposal submitted successfully. ID: $proposalId',
          'تم إرسال العرض بنجاح. الرقم: $proposalId',
        ),
      );
      // context.go('/tender/${widget.tenderId}/ranking');
    } catch (e) {
      final err = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        msg = err;
      });
      _toast(err);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppPageBackButton(
          fallbackRoute: '/tender/${widget.tenderId}',
        ),
        title: Text(context.tr('Submit Proposal', 'تقديم عرض')),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh lowest offer', 'تحديث أقل عرض'),
            onPressed: loadingLowest ? null : _loadCurrentLowest,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.trending_down, color: Color(0xFF0B3C8C)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Current Lowest Offer', 'أقل عرض حالي'),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (loadingLowest)
                            Text(
                              context.tr(
                                'Checking the latest submitted price...',
                                'جارٍ التحقق من أحدث سعر مقدّم...',
                              ),
                            )
                          else if (currentLowest == null)
                            Text(
                              context.tr(
                                'No earlier proposal was found. You can submit the first offer.',
                                'لم يتم العثور على عرض سابق. يمكنك تقديم أول عرض.',
                              ),
                            )
                          else
                            Text(
                              context.tr(
                                'You must submit less than EGP ${currentLowest!.toStringAsFixed(0)}.',
                                'يجب أن تقدّم أقل من ${context.l10n.t('EGP', 'ج.م')} ${currentLowest!.toStringAsFixed(0)}.',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.tr('Lowest price (EGP)', 'أقل سعر (ج.م)'),
                prefixIcon: Icon(Icons.payments),
                hintText: context.tr('e.g. 250000', 'مثال: 250000'),
              ),
              onSubmitted: (_) => loading || loadingLowest ? null : _submit(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: loading || loadingLowest ? null : _submit,
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('Submit', 'إرسال')),
              ),
            ),
            const SizedBox(height: 12),
            if (msg != null)
              Text(
                msg!,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
