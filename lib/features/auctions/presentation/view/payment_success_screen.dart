import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String title;
  final String amountLabel;
  final String? reference;
  final bool isTender;

  const PaymentSuccessScreen({
    super.key,
    required this.title,
    required this.amountLabel,
    required this.isTender,
    this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.tr('Payment Complete', 'اكتمل الدفع')),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B3C8C), Color(0xFF0A2F6E)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.14),
                      blurRadius: 24,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.14),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(.18)),
                      ),
                      child: const Icon(
                        Icons.celebration_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.tr('Congratulations!', 'تهانينا!'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isTender
                          ? context.tr(
                              'Your tender payment has been submitted successfully.',
                              'تم إرسال دفعة المناقصة الخاصة بك بنجاح.',
                            )
                          : context.tr(
                              'Your auction payment has been submitted successfully.',
                              'تم إرسال دفعة المزاد الخاصة بك بنجاح.',
                            ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.84),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SummaryCard(
                      title: title,
                      amountLabel: amountLabel,
                      reference: reference,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go('/my-payments'),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(context.tr('Back to My Payments', 'العودة إلى مدفوعاتي')),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFDC32D),
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.home_outlined),
                        label: Text(context.tr('Go to Home', 'الذهاب إلى الرئيسية')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(.28)),
                          minimumSize: const Size.fromHeight(52),
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
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amountLabel;
  final String? reference;

  const _SummaryCard({
    required this.title,
    required this.amountLabel,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailLine(
            label: context.tr('Invoice', 'الفاتورة'),
            value: title,
          ),
          const SizedBox(height: 10),
          _DetailLine(
            label: context.tr('Amount', 'المبلغ'),
            value: amountLabel,
          ),
          if (reference != null && reference!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailLine(
              label: context.tr('Reference', 'المرجع'),
              value: reference!,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(.72),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
