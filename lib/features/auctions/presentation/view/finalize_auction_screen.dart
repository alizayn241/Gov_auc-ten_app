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
  bool _loadingSummary = true;
  String? _error;
  _FinalizeResult? _result;
  String? _winnerName;
  int _bidCount = 0;
  String? _auctionStatus;

  final _remote = AuctionsAdminRemoteDataSource(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loadingSummary = true;
      _error = null;
    });

    try {
      final auction = await Supabase.instance.client
          .from('auctions')
          .select('status')
          .eq('id', widget.auctionId)
          .single();

      final bids = await Supabase.instance.client
          .from('bids')
          .select('id')
          .eq('auction_id', widget.auctionId);

      if (!mounted) return;
      setState(() {
        _auctionStatus = (auction['status'] ?? '').toString();
        _bidCount = (bids as List).length;
        _loadingSummary = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSummary = false;
      });
    }
  }

  Future<void> _finalize() async {
    if (_bidCount == 0) {
      setState(() {
        _error = context.tr(
          'This auction cannot be finalized yet because no bids have been placed.',
          'لا يمكن إنهاء هذا المزاد بعد لأنه لا توجد أي مزايدات مسجلة.',
        );
        _result = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _winnerName = null;
    });

    try {
      final res = await _remote.finalizeAuction(widget.auctionId);
      final result = _FinalizeResult.fromMap(res);
      final winnerName = await _loadWinnerName(result.winnerUserId);
      if (!mounted) return;
      setState(() {
        _result = result;
        _winnerName = winnerName;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _error = message.contains('no bids')
            ? context.tr(
                'This auction has no bids yet, so the system cannot select a winner or create an invoice.',
                'هذا المزاد لا يحتوي على مزايدات بعد، لذلك لا يمكن للنظام اختيار فائز أو إنشاء فاتورة.',
              )
            : message;
        _loading = false;
      });
    }
  }

  Future<String?> _loadWinnerName(String userId) async {
    if (userId.trim().isEmpty) return null;

    try {
      final adminUsers = await Supabase.instance.client.rpc('admin_list_users');
      if (adminUsers is List) {
        for (final row in adminUsers) {
          final map = Map<String, dynamic>.from(row as Map);
          final id = ((map['user_id'] ?? map['id']) ?? '').toString();
          if (id != userId) continue;
          final displayName = (map['display_name'] ?? map['name'] ?? '')
              .toString()
              .trim();
          if (displayName.isNotEmpty) return displayName;
        }
      }
    } catch (_) {
      // Fall back to public profiles if the admin RPC is unavailable.
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();

      final displayName = (profile?['display_name'] ?? '').toString().trim();
      if (displayName.isNotEmpty) return displayName;
    } catch (_) {
      // Keep the user id as fallback.
    }

    return null;
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
                  const SizedBox(height: 12),
                  if (_loadingSummary)
                    const LinearProgressIndicator(minHeight: 3)
                  else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _bidCount > 0
                            ? Colors.green.withOpacity(.08)
                            : Colors.orange.withOpacity(.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _bidCount > 0
                              ? Colors.green.withOpacity(.25)
                              : Colors.orange.withOpacity(.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              'Current status: ${_auctionStatus ?? '-'}',
                              'الحالة الحالية: ${_auctionStatus ?? '-'}',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(
                              'Recorded bids: $_bidCount',
                              'عدد المزايدات المسجلة: $_bidCount',
                            ),
                          ),
                          if (_bidCount == 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              context.tr(
                                'Place at least one bid before finalizing this auction.',
                                'يجب تسجيل مزايدة واحدة على الأقل قبل إنهاء هذا المزاد.',
                              ),
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading || _loadingSummary || _bidCount == 0
                          ? null
                          : _finalize,
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
                      value: _winnerName?.isNotEmpty == true
                          ? '${_winnerName!} (${_result!.winnerUserId})'
                          : _result!.winnerUserId,
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
                            onPressed: null,
                            icon: const Icon(Icons.payments_outlined),
                            label: Text(context.tr('User Pays From My Payments', 'المستخدم يدفع من مدفوعاتي')),
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
