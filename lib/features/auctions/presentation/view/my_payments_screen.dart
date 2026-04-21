import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/services/auction_automation_service.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/sources/auctions_admin_remote_data_source.dart';

class MyPaymentsScreen extends StatefulWidget {
  const MyPaymentsScreen({super.key});

  @override
  State<MyPaymentsScreen> createState() => _MyPaymentsScreenState();
}

class _MyPaymentsScreenState extends State<MyPaymentsScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<_InvoiceViewData> _items = const [];

  final _remote = AuctionsAdminRemoteDataSource(Supabase.instance.client);
  late final AuctionAutomationService _automation;

  @override
  void initState() {
    super.initState();
    _automation = AuctionAutomationService(Supabase.instance.client);
    _load();
  }

  Future<void> _runAuctionExpiryCheck() async {
    final result = await _automation.checkExpiredAuctions();
    if (result['success'] != true) {
      debugPrint('Auction expiry check failed: ${result['error']}');
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('Please login first');
      }

      await _runAuctionExpiryCheck();

      final invoiceRows = await Supabase.instance.client
          .from('invoices')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final invoices = (invoiceRows as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final auctionIds = invoices
          .map((e) => (e['auction_id'] ?? '').toString())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      final tenderIds = invoices
          .map((e) => (e['tender_id'] ?? '').toString())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      final invoiceIds = invoices
          .map((e) => (e['id'] ?? '').toString())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      final auctions = <String, Map<String, dynamic>>{};
      if (auctionIds.isNotEmpty) {
        final rows = await Supabase.instance.client
            .from('auctions')
            .select('id,title,category,end_time')
            .inFilter('id', auctionIds);
        for (final row in (rows as List)) {
          final map = Map<String, dynamic>.from(row as Map);
          auctions[(map['id'] ?? '').toString()] = map;
        }
      }

      final tenders = <String, Map<String, dynamic>>{};
      if (tenderIds.isNotEmpty) {
        final rows = await Supabase.instance.client
            .from('tenders')
            .select('id,title,entity,reference_no,submission_deadline')
            .inFilter('id', tenderIds);
        for (final row in (rows as List)) {
          final map = Map<String, dynamic>.from(row as Map);
          tenders[(map['id'] ?? '').toString()] = map;
        }
      }

      final paymentsByInvoice = <String, List<_PaymentMini>>{};
      if (invoiceIds.isNotEmpty) {
        final rows = await Supabase.instance.client
            .from('payments')
            .select('*')
            .inFilter('invoice_id', invoiceIds)
            .order('created_at', ascending: false);

        for (final row in (rows as List)) {
          final payment = _PaymentMini.fromMap(
            Map<String, dynamic>.from(row as Map),
          );
          paymentsByInvoice.putIfAbsent(payment.invoiceId, () => []).add(payment);
        }
      }

      if (!mounted) return;
      setState(() {
        _items = invoices
            .map(
              (invoice) => _InvoiceViewData.fromMap(
                invoice,
                auction: auctions[(invoice['auction_id'] ?? '').toString()],
                tender: tenders[(invoice['tender_id'] ?? '').toString()],
                payments:
                    paymentsByInvoice[(invoice['id'] ?? '').toString()] ??
                        const [],
              ),
            )
            .toList();
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

  Future<void> _openPaySheet(_InvoiceViewData invoice) async {
    final amountCtrl =
        TextEditingController(text: invoice.total.toStringAsFixed(0));
    final refCtrl = TextEditingController();
    var method = 'bank_transfer';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final l10n = context.l10n;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.isTender
                          ? context.tr('Pay Tender Invoice', 'سداد فاتورة المناقصة')
                          : context.tr('Pay Auction Invoice', 'سداد فاتورة المزاد'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      invoice.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: context.tr('Amount', 'المبلغ'),
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: method,
                      items: [
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text(context.tr('bank transfer', 'تحويل بنكي')),
                        ),
                        DropdownMenuItem(
                          value: 'card',
                          child: Text(context.tr('card', 'بطاقة')),
                        ),
                        DropdownMenuItem(
                          value: 'wallet',
                          child: Text(context.tr('wallet', 'محفظة')),
                        ),
                        DropdownMenuItem(
                          value: 'cash',
                          child: Text(context.tr('cash', 'نقداً')),
                        ),
                      ],
                      onChanged: (v) =>
                          setSheetState(() => method = v ?? 'bank_transfer'),
                      decoration: InputDecoration(
                        labelText: context.tr('Payment Method', 'طريقة الدفع'),
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: refCtrl,
                      decoration: InputDecoration(
                        labelText: context.tr(
                          'Reference / Transaction ID',
                          'المرجع / رقم العملية',
                        ),
                        prefixIcon: Icon(Icons.receipt_long_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting
                            ? null
                            : () async {
                                final amount =
                                    num.tryParse(amountCtrl.text.trim());
                                final reference = refCtrl.text.trim();

                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.tr(
                                          'Enter a valid amount',
                                          'أدخل مبلغاً صحيحاً',
                                        ),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (amount < invoice.total) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.tr(
                                          'Amount must be at least EGP ${invoice.total.toStringAsFixed(0)}',
                                          'يجب ألا يقل المبلغ عن ${l10n.t('EGP', 'ج.م')} ${invoice.total.toStringAsFixed(0)}',
                                        ),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (reference.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.tr(
                                          'Enter a payment reference',
                                          'أدخل مرجع الدفع',
                                        ),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _submitting = true);
                                try {
                                  await _remote.confirmPayment(
                                    invoiceId: invoice.id,
                                    amount: amount,
                                    method: method,
                                    reference: reference,
                                  );
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  await _load();
                                  if (!mounted) return;
                                  final uri = Uri(
                                    path: '/payment/success',
                                    queryParameters: {
                                      'title': invoice.title,
                                      'amount': 'EGP ' + amount.toStringAsFixed(0),
                                      'reference': reference,
                                      'kind': invoice.isTender ? 'tender' : 'auction',
                                    },
                                  );
                                  this.context.push(uri.toString());
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceFirst(
                                              'Exception: ',
                                              '',
                                            ),
                                      ),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _submitting = false);
                                  }
                                }
                              },
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.verified_outlined),
                        label: Text(
                          context.tr('Submit Payment', 'إرسال الدفع'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('My Payments', 'مدفوعاتي')),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 10),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _load,
                          child: Text(context.tr('Retry', 'إعادة المحاولة')),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_items.isEmpty)
                      _EmptyState(
                        title: context.tr('No invoices yet', 'لا توجد فواتير بعد'),
                        subtitle: context.tr(
                          'When you win an auction or tender and an invoice is created, you will be able to pay it here.',
                          'عند الفوز بمزاد أو مناقصة وإنشاء فاتورة، ستتمكن من سدادها من هنا.',
                        ),
                        icon: Icons.receipt_long_outlined,
                      )
                    else
                      ..._items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InvoiceCard(
                            item: item,
                            onPay: item.isPaid ? null : () => _openPaySheet(item),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final _InvoiceViewData item;
  final VoidCallback? onPay;

  const _InvoiceCard({required this.item, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                _StatusChip(text: item.invoiceStatus),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${item.kindLabel} | ${item.subtitle} | ${context.tr('Due', 'الاستحقاق')}: ${item.dueLabel}',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.tr('Amount due', 'المبلغ المستحق')}: ${context.l10n.t('EGP', 'ج.م')} ${item.total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (item.payments.isNotEmpty)
              ...item.payments.take(2).map(
                (payment) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${context.tr('Payment', 'دفعة')} ${payment.status}: ${context.l10n.t('EGP', 'ج.م')} ${payment.amount.toStringAsFixed(0)} | ${payment.reference.isEmpty ? payment.method : payment.reference}',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(item.viewRoute),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(item.viewLabel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onPay,
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(
                      item.isPaid
                          ? context.tr('Paid', 'مدفوع')
                          : context.tr('Pay Now', 'ادفع الآن'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceViewData {
  final String id;
  final String auctionId;
  final String tenderId;
  final String title;
  final String subtitle;
  final double total;
  final String invoiceStatus;
  final DateTime? dueAt;
  final List<_PaymentMini> payments;

  const _InvoiceViewData({
    required this.id,
    required this.auctionId,
    required this.tenderId,
    required this.title,
    required this.subtitle,
    required this.total,
    required this.invoiceStatus,
    required this.dueAt,
    required this.payments,
  });

  factory _InvoiceViewData.fromMap(
    Map<String, dynamic> invoice, {
    required Map<String, dynamic>? auction,
    required Map<String, dynamic>? tender,
    required List<_PaymentMini> payments,
  }) {
    final auctionId = (invoice['auction_id'] ?? '').toString();
    final tenderId = (invoice['tender_id'] ?? '').toString();
    final isTender = tenderId.isNotEmpty;

    return _InvoiceViewData(
      id: (invoice['id'] ?? '').toString(),
      auctionId: auctionId,
      tenderId: tenderId,
      title: isTender
          ? (tender?['title'] ?? 'Tender').toString()
          : (auction?['title'] ?? 'Auction').toString(),
      subtitle: isTender
          ? (tender?['entity'] ?? tender?['reference_no'] ?? 'Tender')
              .toString()
          : (auction?['category'] ?? 'Auction').toString(),
      total:
          (invoice['total'] as num?)?.toDouble() ??
          (invoice['amount'] as num?)?.toDouble() ??
          0,
      invoiceStatus: _normalizeInvoiceStatus(invoice['status']),
      dueAt: DateTime.tryParse((invoice['due_at'] ?? '').toString())?.toLocal(),
      payments: payments,
    );
  }

  bool get isTender => tenderId.isNotEmpty;

  bool get isPaid => invoiceStatus.toLowerCase() == 'paid';

  String get kindLabel => isTender ? 'Tender' : 'Auction';

  String get viewRoute => isTender ? '/tender/$tenderId' : '/auction/$auctionId';

  String get viewLabel => isTender ? 'View Tender' : 'View Auction';

  String get dueLabel {
    final d = dueAt;
    if (d == null) return '-';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  static String _normalizeInvoiceStatus(dynamic rawStatus) {
    final status = (rawStatus ?? '').toString().trim().toLowerCase();
    switch (status) {
      case 'pending':
      case 'awaiting_payment':
        return 'unpaid';
      case '':
        return 'unpaid';
      default:
        return status;
    }
  }
}

class _PaymentMini {
  final String invoiceId;
  final double amount;
  final String status;
  final String method;
  final String reference;

  const _PaymentMini({
    required this.invoiceId,
    required this.amount,
    required this.status,
    required this.method,
    required this.reference,
  });

  factory _PaymentMini.fromMap(Map<String, dynamic> map) {
    return _PaymentMini(
      invoiceId: (map['invoice_id'] ?? '').toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      status: (map['status'] ?? '').toString(),
      method: (map['method'] ?? '').toString(),
      reference: (map['reference'] ?? '').toString(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;

  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final color = switch (lower) {
      'paid' => Colors.green,
      'unpaid' => const Color(0xFF7A5D00),
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
