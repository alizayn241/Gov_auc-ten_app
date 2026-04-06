import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/sources/auctions_admin_remote_data_source.dart';

class FinalizeAuctionScreen extends StatefulWidget {
  final String auctionId;
  const FinalizeAuctionScreen({super.key, required this.auctionId});

  @override
  State<FinalizeAuctionScreen> createState() => _FinalizeAuctionScreenState();
}

class _FinalizeAuctionScreenState extends State<FinalizeAuctionScreen> {
  bool _loading = false;
  String? _error;
  _FinalizeResult? _result;

  final _remote = AuctionsAdminRemoteDataSource(Supabase.instance.client);

  Future<void> _finalize() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final res = await _remote.finalizeAuction(widget.auctionId);
      if (!mounted) return;
      setState(() {
        _result = _FinalizeResult.fromMap(res);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Finalize Auction', 'إنهاء المزاد')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
                Text(
                  context.tr('Finalize Winner Selection', 'إنهاء اختيار الفائز'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    'This step selects the winning bidder and generates the invoice needed for payment confirmation.',
                    'تحدد هذه الخطوة المزايد الفائز وتنشئ الفاتورة المطلوبة لتأكيد الدفع.',
                  ),
                  style: TextStyle(color: Colors.white.withOpacity(.82)),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    context.tr('Auction ID: ${widget.auctionId}', 'رقم المزاد: ${widget.auctionId}'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Action', 'الإجراء'),
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      'Use this action after participant review is complete and the auction is ready to determine the winner.',
                      'استخدم هذا الإجراء بعد اكتمال مراجعة المشاركين وعندما يصبح المزاد جاهزاً لتحديد الفائز.',
                    ),
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _finalize,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.emoji_events_outlined),
                      label: Text(context.tr('Finalize Auction', 'إنهاء المزاد')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            _MessageCard(
              icon: Icons.error_outline,
              color: Colors.red,
              title: context.tr('Finalize failed', 'فشل الإنهاء'),
              message: _error!,
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('Auction Finalized', 'تم إنهاء المزاد'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ResultRow(
                      label: context.tr('Winner User', 'المستخدم الفائز'),
                      value: _result!.winnerUserId,
                    ),
                    _ResultRow(
                      label: context.tr('Winning Bid', 'المزايدة الفائزة'),
                      value:
                          '${context.l10n.t('EGP', 'ج.م')} ${_result!.winningBid.toStringAsFixed(0)}',
                    ),
                    _ResultRow(
                      label: context.tr('Invoice ID', 'رقم الفاتورة'),
                      value: _result!.invoiceId,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(
                              '/admin/auctions/${widget.auctionId}/manage',
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(context.tr('Back to Manage', 'العودة للإدارة')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => context.push(
                              '/admin/auctions/${widget.auctionId}/payment',
                            ),
                            icon: const Icon(Icons.payments_outlined),
                            label: Text(context.tr('Go to Payment', 'الانتقال إلى الدفع')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FinalizeResult {
  final String winnerUserId;
  final double winningBid;
  final String invoiceId;

  const _FinalizeResult({
    required this.winnerUserId,
    required this.winningBid,
    required this.invoiceId,
  });

  factory _FinalizeResult.fromMap(Map<String, dynamic> map) {
    return _FinalizeResult(
      winnerUserId: (map['winnerUserId'] ?? '').toString(),
      winningBid: (map['winningBid'] as num?)?.toDouble() ?? 0,
      invoiceId: (map['invoiceId'] ?? '').toString(),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _MessageCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
