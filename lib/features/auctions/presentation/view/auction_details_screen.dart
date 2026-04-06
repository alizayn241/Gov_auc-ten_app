import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';
import 'package:gov_auction_app/core/widgets/app_image.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/auction.dart';
import '../../data/models/bid.dart';
import '../../../auth/presentation/viewmodel/auth_view_model.dart';
import '../viewmodel/auctions_view_model.dart';

class AuctionDetailsScreen extends ConsumerStatefulWidget {
  final String auctionId;

  const AuctionDetailsScreen({
    super.key,
    required this.auctionId,
  });

  @override
  ConsumerState<AuctionDetailsScreen> createState() =>
      _AuctionDetailsScreenState();
}

class _AuctionDetailsScreenState extends ConsumerState<AuctionDetailsScreen> {
  final _bidController = TextEditingController();

  late Future<Auction> _detailsFuture;
  late Future<List<Bid>> _historyFuture;

  Auction? _auction; // cached
  List<Bid> _history = [];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    final vm = ref.read(auctionsViewModelProvider.notifier);

    _detailsFuture = vm.fetchDetails(widget.auctionId);
    _historyFuture = vm.fetchBidHistory(widget.auctionId);
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  Future<void> _refreshHistory() async {
    final vm = ref.read(auctionsViewModelProvider.notifier);
    setState(() => _historyLoading = true);

    try {
      final list = await vm.fetchBidHistory(widget.auctionId);
      if (!mounted) return;
      setState(() {
        _history = list;
        _historyLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _historyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(auctionsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: const AppPageBackButton(fallbackRoute: '/auctions'),
        title: Text(context.tr('Auction Details', 'تفاصيل المزاد')),
      ),
      body: SafeArea(
        child: FutureBuilder<Auction>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: Text(context.tr('Auction not found', 'المزاد غير موجود')),
              );
            }

            // cache auction once
            _auction ??= snapshot.data!;
            final auction = _auction!;
            final shareUrl = 'https://gov-auction.app/auction/${auction.id}';

            // ✅ initialize history once (from future) then keep local list
            return FutureBuilder<List<Bid>>(
              future: _historyFuture,
              builder: (context, hs) {
                if (_history.isEmpty && hs.hasData) {
                  _history = hs.data!;
                  _historyLoading = false;
                } else if (hs.connectionState == ConnectionState.waiting &&
                    _history.isEmpty) {
                  _historyLoading = true;
                }

                return LayoutBuilder(
                  builder: (context, c) {
                    final isWide = c.maxWidth >= 980;

                    final left = _LeftDetailsPanel(auction: auction);

                    final right = _RightBidPanel(
                      auction: auction,
                      bidController: _bidController,
                      history: _history,
                      historyLoading: _historyLoading,
                      onRefreshHistory: _refreshHistory,
                      onToggleWatch: () async {
                        await vm.toggleWatch(auction.id);
                        setState(() {
                          _auction =
                              auction.copyWith(isWatchlisted: !auction.isWatchlisted);
                        });

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr('Updated watchlist', 'تم تحديث قائمة المتابعة'),
                            ),
                          ),
                        );
                      },
                      onShare: () async {
                        await Clipboard.setData(ClipboardData(text: shareUrl));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('Link copied', 'تم نسخ الرابط')),
                          ),
                        );
                      },
                      onSubmitBid: (amount) async {
                        final updated = await vm.submitBid(auction.id, amount);

                        // ✅ 1) update UI currentBid instantly
                        setState(() => _auction = updated);

                        // ✅ 2) add to local history instantly
                        final auth = ref.read(authViewModelProvider);
                        final newBid = Bid(
                          id: '${auction.id}_${DateTime.now().millisecondsSinceEpoch}',
                          auctionId: auction.id,
                          userId: auth.userId ?? 'me',
                          amount: amount,
                          timestamp: DateTime.now(),
                          isWinner: null,
                        );

                        setState(() {
                          _history = [newBid, ..._history];
                        });

                        // ✅ 3) refresh from source in background (sync)
                        unawaited(_refreshHistory());
                      },
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isWide) ...[
                            left,
                            const SizedBox(height: 12),
                            right,
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: left),
                                const SizedBox(width: 14),
                                Expanded(flex: 2, child: right),
                              ],
                            ),

                          const SizedBox(height: 18),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/* ------------------------- */
/* Left panel: images + text */
/* ------------------------- */

class _LeftDetailsPanel extends StatelessWidget {
  final Auction auction;
  const _LeftDetailsPanel({required this.auction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final images = auction.images.isNotEmpty
        ? auction.images
        : ['assets/images/auctions/auction_blue_01.jpg'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AppImage(
                  imagePath: images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length.clamp(1, 8),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 94,
                      child: AppImage(
                        imagePath: images[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: cs.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image, size: 22),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.category_outlined,
                  label: auction.category,
                ),
                _InfoPill(
                  icon: Icons.location_on_outlined,
                  label: auction.location,
                ),
                _InfoPill(
                  icon: Icons.apartment_outlined,
                  label: auction.department,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Description', 'الوصف'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(auction.description),

            const SizedBox(height: 18),
            Text(context.tr('Asset Specifications', 'مواصفات الأصل'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),

            _SpecRow(label: context.tr('Category', 'الفئة'), value: auction.category),
            _SpecRow(label: context.tr('Location', 'الموقع'), value: auction.location),
            _SpecRow(label: context.tr('Department', 'الجهة'), value: auction.department),
            _SpecRow(
              label: context.tr('Start Price', 'سعر البداية'),
              value: '${context.l10n.t('EGP', 'ج.م')} ${auction.startPrice.toStringAsFixed(0)}',
            ),
            if (auction.latitude != null && auction.longitude != null) ...[
              const SizedBox(height: 18),
              Text(context.tr('Map Location', 'الموقع على الخريطة'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              _AuctionLocationMap(
                latitude: auction.latitude!,
                longitude: auction.longitude!,
                locationLabel: auction.location,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* ------------------------- */
/* Right panel: bid + actions */
/* ------------------------- */

class _RightBidPanel extends ConsumerStatefulWidget {
  final Auction auction;
  final TextEditingController bidController;

  final List<Bid> history;
  final bool historyLoading;
  final Future<void> Function() onRefreshHistory;

  final Future<void> Function(double amount) onSubmitBid;
  final VoidCallback onToggleWatch;
  final VoidCallback onShare;

  const _RightBidPanel({
    required this.auction,
    required this.bidController,
    required this.history,
    required this.historyLoading,
    required this.onRefreshHistory,
    required this.onSubmitBid,
    required this.onToggleWatch,
    required this.onShare,
  });

  @override
  ConsumerState<_RightBidPanel> createState() => _RightBidPanelState();
}

class _RightBidPanelState extends ConsumerState<_RightBidPanel> {
  String? _bidError;

  @override
  void initState() {
    super.initState();
    widget.bidController.addListener(_validateBidInput);
  }

  @override
  void didUpdateWidget(covariant _RightBidPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bidController != widget.bidController) {
      oldWidget.bidController.removeListener(_validateBidInput);
      widget.bidController.addListener(_validateBidInput);
    }
    _validateBidInput();
  }

  @override
  void dispose() {
    widget.bidController.removeListener(_validateBidInput);
    super.dispose();
  }

  void _validateBidInput() {
    if (widget.auction.endTime.isBefore(DateTime.now())) {
      if (_bidError != null && mounted) {
        setState(() => _bidError = null);
      }
      return;
    }

    final requiredBid = _requiredBid;
    final raw = widget.bidController.text.trim();

    String? nextError;
    if (raw.isNotEmpty) {
      final amount = double.tryParse(raw);
      if (amount == null) {
        nextError = context.tr('Enter a valid amount', 'أدخل مبلغاً صحيحاً');
      } else if (amount < requiredBid) {
        nextError = context.tr(
          'Bid must be at least EGP ${requiredBid.toStringAsFixed(0)}',
          'يجب أن يكون العرض على الأقل ${context.l10n.t('EGP', 'ج.م')} ${requiredBid.toStringAsFixed(0)}',
        );
      }
    }

    if (nextError != _bidError && mounted) {
      setState(() => _bidError = nextError);
    }
  }

  double get _highestKnownBid {
    var highest = widget.auction.currentBid;
    for (final bid in widget.history) {
      if (bid.amount > highest) highest = bid.amount;
    }
    return highest;
  }

  double get _requiredBid => _highestKnownBid + 10;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authViewModelProvider);
    final auction = widget.auction;
    final history = widget.history;
    final historyLoading = widget.historyLoading;
    final isAdmin = auth.isAdmin;
    final canManageWatchlist = auth.isAuthenticated && !isAdmin;
    final auctionEnded = !auction.endTime.isAfter(DateTime.now());
    final canPlaceBid = auth.isAuthenticated && !isAdmin && !auctionEnded;

    final remainingTick = Stream<DateTime>.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );

    final highestKnownBid = _highestKnownBid;
    final minBid = _requiredBid;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    auction.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Watchlist', 'قائمة المتابعة'),
                  onPressed: canManageWatchlist ? widget.onToggleWatch : null,
                  icon: Icon(
                    auction.isWatchlisted ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Share', 'مشاركة'),
                  onPressed: widget.onShare,
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.location_on_outlined,
                  label: auction.location,
                ),
                _InfoPill(
                  icon: Icons.apartment_outlined,
                  label: auction.department,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.surfaceContainerHighest,
                    cs.primary.withOpacity(.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('CURRENT HIGHEST BID', 'أعلى عرض حالي'),
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${context.l10n.t('EGP', 'ج.م')} ${highestKnownBid.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<DateTime>(
                    stream: remainingTick,
                    builder: (_, __) {
                      final r = auction.endTime.difference(DateTime.now());
                      final ended = r.isNegative;
                      final text = ended
                          ? context.tr('Auction ended', 'انتهى المزاد')
                          : context.tr(
                              'Ends in ${r.inHours}h ${r.inMinutes.remainder(60)}m ${r.inSeconds.remainder(60)}s',
                              'ينتهي خلال ${r.inHours}س ${r.inMinutes.remainder(60)}د ${r.inSeconds.remainder(60)}ث',
                            );
                      return Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 18,
                            color: ended ? Colors.grey : Colors.deepOrange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                color: ended
                                    ? cs.onSurfaceVariant
                                    : Colors.deepOrange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr(
                        'Min bid: EGP ${minBid.toStringAsFixed(0)}',
                        'الحد الأدنى للمزايدة: ${context.l10n.t('EGP', 'ج.م')} ${minBid.toStringAsFixed(0)}',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (auctionEnded) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.event_busy_outlined, color: cs.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr(
                          'This auction has ended. Bidding is no longer available.',
                          'انتهى هذا المزاد. لم تعد المزايدة متاحة.',
                        ),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!auth.isAuthenticated) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/login'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(context.tr('Login to Bid', 'سجل الدخول للمزايدة')),
                ),
              ),
            ] else if (isAdmin) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EntryFlowTokens.accentWarm.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EntryFlowTokens.accentWarm.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: EntryFlowTokens.accentWarm),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr(
                          'Admin accounts can view auction details, but cannot place bids or add auctions to the watchlist.',
                          'يمكن لحسابات الإدارة عرض تفاصيل المزاد، لكنها لا تستطيع تقديم عروض أو إضافة المزادات إلى قائمة المتابعة.',
                        ),
                        style: TextStyle(
                          color: EntryFlowTokens.accentWarm.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              TextField(
                controller: widget.bidController,
                enabled: !auctionEnded,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: context.tr('Your bid amount', 'مبلغ المزايدة'),
                  prefixIcon: const Icon(Icons.payments),
                  errorText: _bidError,
                ),
              ),
              if (_bidError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.tr(
                      'Highest bid in history is EGP ${highestKnownBid.toStringAsFixed(0)}.',
                      'أعلى عرض في السجل هو ${context.l10n.t('EGP', 'ج.م')} ${highestKnownBid.toStringAsFixed(0)}.',
                    ),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: !canPlaceBid || _bidError != null
                      ? null
                      : () async {
                    final amount =
                        double.tryParse(widget.bidController.text.trim());
                    if (amount == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr('Enter a valid amount', 'أدخل مبلغاً صحيحاً'),
                          ),
                        ),
                      );
                      return;
                    }
                    if (amount < minBid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr(
                              'Bid must be at least EGP ${minBid.toStringAsFixed(0)}',
                              'يجب أن يكون العرض على الأقل ${context.l10n.t('EGP', 'ج.م')} ${minBid.toStringAsFixed(0)}',
                            ),
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await widget.onSubmitBid(amount);
                      widget.bidController.clear();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr('Bid placed successfully', 'تم تقديم العرض بنجاح'),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(context.tr('Submit Bid', 'تقديم العرض')),
                ),
              ),
            ],

            const SizedBox(height: 8),
            Center(
              child: Text(
                context.tr(
                  'By placing a bid, you agree to the Terms of Sale.',
                  'بتقديم عرض، فإنك توافق على شروط البيع.',
                ),
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 14),
            const Divider(),

            Row(
              children: [
                Expanded(
                  child: Text(context.tr('Bid History', 'سجل العروض'),
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: context.tr('Refresh', 'تحديث'),
                  onPressed: () => widget.onRefreshHistory(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (historyLoading && history.isEmpty)
              const LinearProgressIndicator()
            else if (history.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  children: [
                    Text(context.tr('No bids yet.', 'لا توجد عروض بعد.'),
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text(
                      context.tr('Be the first to bid!', 'كن أول من يزايد!'),
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: history.take(6).map((b) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.history),
                    title: Text(
                      '${context.l10n.t('EGP', 'ج.م')} ${b.amount.toStringAsFixed(0)}',
                    ),
                    subtitle: Text(b.timestamp.toLocal().toString()),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- */
/* Spec row widget  */
/* ---------------- */

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AuctionLocationMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String locationLabel;

  const _AuctionLocationMap({
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
  });

  Future<void> _openInGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final position = LatLng(latitude, longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: position,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.gov_auction_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: position,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openInGoogleMaps,
            icon: const Icon(Icons.map_outlined),
            label: Text(
              context.tr('Open In Google Maps', 'فتح في خرائط جوجل'),
            ),
          ),
        ),
      ],
    );
  }
}
