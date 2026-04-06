import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/admin_invoice_item.dart';
import '../../data/sources/auctions_admin_remote_data_source.dart';

class ConfirmPaymentScreen extends StatefulWidget {
  final String resourceId;
  final bool isTender;

  const ConfirmPaymentScreen({
    super.key,
    required String auctionId,
  })  : resourceId = auctionId,
        isTender = false;

  const ConfirmPaymentScreen.tender({
    super.key,
    required String tenderId,
  })  : resourceId = tenderId,
        isTender = true;

  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  final _amount = TextEditingController();
  final _reference = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _result;
  AdminInvoiceItem? _invoice;
  List<_PaymentRecord> _payments = const [];
  String _method = 'bank_transfer';

  final _remote = AuctionsAdminRemoteDataSource(Supabase.instance.client);

  static const _methods = <String>[
    'bank_transfer',
    'card',
    'cash',
    'wallet',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final invoice = widget.isTender
          ? await _remote.getInvoiceByTender(widget.resourceId)
          : await _remote.getInvoiceByAuction(widget.resourceId);

      List<_PaymentRecord> payments = const [];
      if (invoice != null) {
        final rows = await Supabase.instance.client
            .from('payments')
            .select('*')
            .eq('invoice_id', invoice.id)
            .order('created_at', ascending: false);

        payments = (rows as List)
            .map((e) => _PaymentRecord.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _payments = payments;
        if (invoice != null) {
          _amount.text = invoice.total.toStringAsFixed(0);
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _confirm() async {
    final invoice = _invoice;
    if (invoice == null) {
      setState(() => _error = widget.isTender
          ? context.tr('No invoice found for this tender', 'لا توجد فاتورة لهذه المناقصة')
          : context.tr('No invoice found for this auction', 'لا توجد فاتورة لهذا المزاد'));
      return;
    }

    final amount = num.tryParse(_amount.text.trim());
    final reference = _reference.text.trim();

    if (amount == null || amount <= 0) {
      setState(() => _error = context.tr('Enter a valid payment amount', 'أدخل مبلغ دفع صحيح'));
      return;
    }
    if (amount < invoice.total) {
      setState(() => _error =
          context.tr(
            'Payment amount must cover the invoice total of EGP ${invoice.total.toStringAsFixed(0)}',
            'يجب أن يغطي مبلغ الدفع إجمالي الفاتورة ${context.l10n.t('EGP', 'ج.م')} ${invoice.total.toStringAsFixed(0)}',
          ));
      return;
    }
    if (reference.isEmpty) {
      setState(() => _error = context.tr('Enter a payment reference', 'أدخل مرجع الدفع'));
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _result = null;
    });

    try {
      final res = await _remote.confirmPayment(
        invoiceId: invoice.id,
        amount: amount,
        method: _method,
        reference: reference,
      );

      if (!mounted) return;
      setState(() {
        _result = context.tr(
          'Payment confirmed successfully. Payment ID: ${(res['paymentId'] ?? '').toString()}',
          'تم تأكيد الدفع بنجاح. رقم الدفعة: ${(res['paymentId'] ?? '').toString()}',
        );
        _submitting = false;
      });
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  bool get _isPaid => (_invoice?.status ?? '').toLowerCase() == 'paid';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Confirm Payment', 'تأكيد الدفع')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            icon: const Icon(Icons.refresh),
            onPressed: _loading || _submitting ? null : _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_invoice == null)
                  _EmptyInvoiceCard(
                    isTender: widget.isTender,
                    onBack: () => context.go('/admin'),
                  )
                else ...[
                  _HeroSummary(
                    invoice: _invoice!,
                    paymentCount: _payments.length,
                    isTender: widget.isTender,
                  ),
                  const SizedBox(height: 14),
                  _InvoiceCard(
                    invoice: _invoice!,
                    isTender: widget.isTender,
                  ),
                  const SizedBox(height: 14),
                  _FormCard(
                    amountController: _amount,
                    referenceController: _reference,
                    selectedMethod: _method,
                    methods: _methods,
                    submitting: _submitting,
                    invoice: _invoice!,
                    isPaid: _isPaid,
                    onMethodChanged: (value) =>
                        setState(() => _method = value),
                    onConfirm: _confirm,
                  ),
                  const SizedBox(height: 14),
                  _PaymentsCard(payments: _payments),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _MessageCard(
                    icon: Icons.error_outline,
                    color: Colors.red,
                    message: _error!,
                  ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 14),
                  _MessageCard(
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    message: _result!,
                  ),
                ],
              ],
            ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  final AdminInvoiceItem invoice;
  final int paymentCount;
  final bool isTender;

  const _HeroSummary({
    required this.invoice,
    required this.paymentCount,
    required this.isTender,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = invoice.status.toLowerCase() == 'paid';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3C8C), Color(0xFF0A2F6E)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.payments_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTender
                          ? context.tr('Tender Payment Console', 'لوحة دفع المناقصة')
                          : context.tr('Auction Payment Console', 'لوحة دفع المزاد'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTender
                          ? context.tr(
                              'Track the tender invoice, confirm the payment, and review payment records.',
                              'تابع فاتورة المناقصة وأكد الدفع وراجع سجلات الدفعات.',
                            )
                          : context.tr(
                              'Track the invoice, confirm the payment, and review payment records.',
                              'تابع الفاتورة وأكد الدفع وراجع سجلات الدفعات.',
                            ),
                      style: TextStyle(color: Colors.white.withOpacity(.82)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                label: context.tr('Invoice Total', 'إجمالي الفاتورة'),
                value: '${context.l10n.t('EGP', 'ج.م')} ${invoice.total.toStringAsFixed(0)}',
              ),
              _MetricPill(
                label: context.tr('Status', 'الحالة'),
                value: isPaid ? context.tr('Paid', 'مدفوع') : context.tr('Pending', 'معلّق'),
              ),
              _MetricPill(
                label: context.tr('Payments', 'الدفعات'),
                value: context.tr('$paymentCount records', '$paymentCount سجلات'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(.75),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final AdminInvoiceItem invoice;
  final bool isTender;

  const _InvoiceCard({
    required this.invoice,
    required this.isTender,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Invoice Details', 'تفاصيل الفاتورة'),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _DetailRow(label: context.tr('Invoice ID', 'رقم الفاتورة'), value: invoice.id),
            _DetailRow(
              label: isTender ? context.tr('Tender ID', 'رقم المناقصة') : context.tr('Auction ID', 'رقم المزاد'),
              value: isTender ? invoice.tenderId : invoice.auctionId,
            ),
            _DetailRow(
              label: isTender ? context.tr('Winner Vendor', 'المورد الفائز') : context.tr('Winner User', 'المستخدم الفائز'),
              value: invoice.userId,
            ),
            _DetailRow(
              label: context.tr('Status', 'الحالة'),
              value: invoice.status,
              accent: _statusColor(invoice.status),
            ),
            _DetailRow(
              label: context.tr('Total', 'الإجمالي'),
              value: '${context.l10n.t('EGP', 'ج.م')} ${invoice.total.toStringAsFixed(0)}',
            ),
            _DetailRow(label: context.tr('Due At', 'تاريخ الاستحقاق'), value: _fmtDate(invoice.dueAt)),
            _DetailRow(label: context.tr('Created', 'تاريخ الإنشاء'), value: _fmtDate(invoice.createdAt)),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return const Color(0xFF7A5D00);
      default:
        return Colors.grey;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;

  const _DetailRow({
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final String selectedMethod;
  final List<String> methods;
  final bool submitting;
  final bool isPaid;
  final AdminInvoiceItem invoice;
  final ValueChanged<String> onMethodChanged;
  final VoidCallback onConfirm;

  const _FormCard({
    required this.amountController,
    required this.referenceController,
    required this.selectedMethod,
    required this.methods,
    required this.submitting,
    required this.isPaid,
    required this.invoice,
    required this.onMethodChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Confirm Real Payment', 'تأكيد الدفع الفعلي'),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              isPaid
                  ? context.tr(
                      'This invoice is already marked as paid.',
                      'تم تعليم هذه الفاتورة كمدفوعة بالفعل.',
                    )
                  : context.tr(
                      'Enter the actual paid amount, payment method, and external reference.',
                      'أدخل مبلغ الدفع الفعلي وطريقة الدفع والمرجع الخارجي.',
                    ),
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountController,
              enabled: !isPaid && !submitting,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: context.tr('Paid Amount', 'المبلغ المدفوع'),
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedMethod,
              items: methods
                  .map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Text(
                        context.tr(method.replaceAll('_', ' '), _methodLabel(method)),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: isPaid || submitting
                  ? null
                  : (value) {
                      if (value != null) onMethodChanged(value);
                    },
              decoration: InputDecoration(
                labelText: context.tr('Payment Method', 'طريقة الدفع'),
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: referenceController,
              enabled: !isPaid && !submitting,
              decoration: InputDecoration(
                labelText: context.tr(
                  'Reference / Transaction ID',
                  'المرجع / رقم العملية',
                ),
                prefixIcon: Icon(Icons.receipt_long_outlined),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr(
                        'Expected invoice amount: EGP ${invoice.total.toStringAsFixed(0)}',
                        'قيمة الفاتورة المتوقعة: ${context.l10n.t('EGP', 'ج.م')} ${invoice.total.toStringAsFixed(0)}',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isPaid || submitting ? null : onConfirm,
                icon: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_outlined),
                label: Text(
                  isPaid
                      ? context.tr('Already Paid', 'مدفوع بالفعل')
                      : context.tr('Confirm Payment', 'تأكيد الدفع'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentsCard extends StatelessWidget {
  final List<_PaymentRecord> payments;

  const _PaymentsCard({required this.payments});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Recent Payments', 'الدفعات الأخيرة'),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (payments.isEmpty)
              Text(
                context.tr(
                  'No payment records yet for this invoice.',
                  'لا توجد سجلات دفع لهذه الفاتورة حتى الآن.',
                ),
                style: TextStyle(color: cs.onSurfaceVariant),
              )
            else
              ...payments.map(
                (payment) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${context.l10n.t('EGP', 'ج.م')} ${payment.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _StatusBadge(status: payment.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr(
                            'Method: ${payment.method.isEmpty ? '-' : payment.method}',
                            'الطريقة: ${payment.method.isEmpty ? '-' : _methodLabel(payment.method)}',
                          ),
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        Text(
                          context.tr(
                            'Reference: ${payment.reference.isEmpty ? '-' : payment.reference}',
                            'المرجع: ${payment.reference.isEmpty ? '-' : payment.reference}',
                          ),
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        Text(
                          context.tr(
                            'Created: ${_fmtDate(payment.createdAt)}',
                            'تاريخ الإنشاء: ${_fmtDate(payment.createdAt)}',
                          ),
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        if (payment.paidAt != null)
                          Text(
                            context.tr(
                              'Paid At: ${_fmtDate(payment.paidAt)}',
                              'تاريخ الدفع: ${_fmtDate(payment.paidAt)}',
                            ),
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final color = switch (lower) {
      'paid' => Colors.green,
      'pending' => const Color(0xFF7A5D00),
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _MessageCard({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _EmptyInvoiceCard extends StatelessWidget {
  final VoidCallback onBack;
  final bool isTender;

  const _EmptyInvoiceCard({
    required this.onBack,
    required this.isTender,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              context.tr('No invoice found yet', 'لا توجد فاتورة حتى الآن'),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              isTender
                  ? context.tr(
                      'Award the tender first so the system can generate the invoice for the winning vendor.',
                      'قم بترسية المناقصة أولاً حتى يتمكن النظام من إنشاء الفاتورة للمورد الفائز.',
                    )
                  : context.tr(
                      'Finalize the auction first so the system can generate the invoice for the winner.',
                      'قم بإنهاء المزاد أولاً حتى يتمكن النظام من إنشاء الفاتورة للفائز.',
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(context.tr('Back to Admin', 'العودة للإدارة')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRecord {
  final String id;
  final double amount;
  final String status;
  final String method;
  final String reference;
  final DateTime createdAt;
  final DateTime? paidAt;

  const _PaymentRecord({
    required this.id,
    required this.amount,
    required this.status,
    required this.method,
    required this.reference,
    required this.createdAt,
    required this.paidAt,
  });

  factory _PaymentRecord.fromMap(Map<String, dynamic> map) {
    return _PaymentRecord(
      id: (map['id'] ?? '').toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      status: (map['status'] ?? '').toString(),
      method: (map['method'] ?? '').toString(),
      reference: (map['reference'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      paidAt: DateTime.tryParse((map['paid_at'] ?? '').toString())?.toLocal(),
    );
  }
}

String _fmtDate(DateTime? d) => d == null ? '-' : d.toLocal().toString();

String _methodLabel(String method) {
  switch (method) {
    case 'bank_transfer':
      return 'تحويل بنكي';
    case 'card':
      return 'بطاقة';
    case 'cash':
      return 'نقداً';
    case 'wallet':
      return 'محفظة';
    default:
      return method.replaceAll('_', ' ');
  }
}
