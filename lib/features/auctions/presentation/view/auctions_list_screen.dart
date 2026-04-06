import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/auction.dart';
import '../viewmodel/auctions_state.dart';
import '../viewmodel/auctions_view_model.dart';
import '../widgets/fed_auction_card.dart';

class AuctionsListScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialSearch;

  const AuctionsListScreen({super.key, this.initialCategory, this.initialSearch});

  @override
  ConsumerState<AuctionsListScreen> createState() => _AuctionsListScreenState();
}

class _AuctionsListScreenState extends ConsumerState<AuctionsListScreen> {
  String _category = 'All';
  String _status = 'All';
  RangeValues _priceRange = const RangeValues(0, 1000000);

  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();

    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _category = widget.initialCategory!;
    }

    if (widget.initialSearch != null && widget.initialSearch!.trim().isNotEmpty) {
      final initialQuery = widget.initialSearch!.trim();
      _searchCtrl.text = initialQuery;
      _search = initialQuery;
    }

    _searchCtrl.addListener(() {
      setState(() => _search = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _category = 'All';
      _status = 'All';
      _priceRange = RangeValues(0, _maxPriceFor(ref.read(auctionsViewModelProvider)));
      _searchCtrl.clear();
      _search = '';
    });
  }

  double _auctionFilterPrice(Auction auction) {
    final startPrice = auction.startPrice;
    final currentBid = auction.currentBid;
    return currentBid > 0 ? currentBid : startPrice;
  }

  double _maxPriceFor(AuctionsState state) {
    final prices = state.items.map(_auctionFilterPrice);
    final maxPrice = prices.isEmpty
        ? 1000000.0
        : prices.reduce((a, b) => a > b ? a : b);
    return maxPrice < 100000 ? 100000 : maxPrice;
  }

  String _displayCategory(BuildContext context, String value) {
    return switch (value) {
      'All' => context.tr('All', 'الكل'),
      'Vehicles' => context.tr('Vehicles', 'مركبات'),
      'Real Estate' => context.tr('Real Estate', 'عقارات'),
      'Electronics' => context.tr('Electronics', 'إلكترونيات'),
      'Industrial' => context.tr('Industrial', 'صناعي'),
      'Jewelry' => context.tr('Jewelry', 'مجوهرات'),
      _ => value,
    };
  }

  String _displayStatus(BuildContext context, String value) {
    return switch (value) {
      'All' => context.tr('All', 'الكل'),
      'Active Auctions' => context.tr('Active Auctions', 'مزادات نشطة'),
      'Ended' => context.tr('Ended', 'منتهية'),
      _ => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(auctionsViewModelProvider);
    final vm = ref.read(auctionsViewModelProvider.notifier);
    final maxPrice = _maxPriceFor(state);
    final clampedPriceRange = RangeValues(
      _priceRange.start.clamp(0, maxPrice).toDouble(),
      _priceRange.end.clamp(0, maxPrice).toDouble(),
    );

    var items = state.items;

    if (_category != 'All') {
      items = items.where((a) => a.category == _category).toList();
    }

    if (_status == 'Active Auctions') {
      items = items.where((a) => a.endTime.isAfter(DateTime.now())).toList();
    } else if (_status == 'Ended') {
      items = items.where((a) => a.endTime.isBefore(DateTime.now())).toList();
    }

    items = items
        .where((a) =>
            _auctionFilterPrice(a) >= clampedPriceRange.start &&
            _auctionFilterPrice(a) <= clampedPriceRange.end)
        .toList();

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      items = items.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.location.toLowerCase().contains(q);
      }).toList();
    }

    final pageTitleBase = (_category == 'All')
        ? context.tr('All Auctions', 'كل المزادات')
        : context.tr(
            '${_displayCategory(context, _category)} Auctions',
            'مزادات ${_displayCategory(context, _category)}',
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitleBase),
        actions: [
          IconButton(
            tooltip: context.tr('Reset', 'إعادة تعيين'),
            icon: const Icon(Icons.refresh),
            onPressed: _resetFilters,
          ),
          IconButton(
            tooltip: context.tr('Filters', 'الفلاتر'),
            icon: const Icon(Icons.tune),
            onPressed: () => _openFiltersSheet(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth >= 900;

          final grid = _AuctionsGrid(
            loading: state.loading,
            error: state.error,
            itemsCount: items.length,
            onRetry: () => vm.loadInitial(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 1,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: isWide ? 1.10 : 1.05,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final a = items[i];
                final img = a.images.isNotEmpty
                    ? a.images.first
                    : 'assets/images/auctions/auction_blue_01.jpg';

                final remaining = a.endTime.difference(DateTime.now());
                final isActive = !remaining.isNegative;
                final isEndingSoon = isActive && remaining.inHours <= 24;

                final showEndingSoon = isEndingSoon;
                final showActive = !showEndingSoon && isActive;

                final timeLeft = !isActive
                    ? context.tr('Ended', 'منتهية')
                    : context.tr(
                        '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left',
                        'متبقي ${remaining.inHours}س ${remaining.inMinutes.remainder(60)}د',
                      );

                return FedAuctionCard(
                  image: img,
                  title: a.title,
                  location: a.location,
                  currentBid: a.currentBid,
                  timeLeft: timeLeft,
                  active: showActive,
                  endingSoon: showEndingSoon,
                  // onTap: () => context.go('/auction/${a.id}'),
                );
              },
            ),
          );

          if (!isWide) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: const _ListHero(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: context.tr('Search listings...', 'ابحث في المزادات...'),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('${items.length} results', '${items.length} نتيجة'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _FilterChip(label: _displayCategory(context, _category)),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: _status == 'All'
                            ? context.tr('Any status', 'أي حالة')
                            : _displayStatus(context, _status),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(child: grid),
              ],
            );
          }

          final header = Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        pageTitleBase,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Text(
                          context.tr('${items.length} listings', '${items.length} مزاد'),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 360,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: context.tr('Search listings...', 'ابحث في المزادات...'),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ],
            ),
          );

          return Row(
            children: [
              SizedBox(
                width: 320,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _FiltersPanel(
                    category: _category,
                    status: _status,
                    priceRange: clampedPriceRange,
                    maxPrice: maxPrice,
                    isBottomSheet: false,
                    onReset: _resetFilters,
                    onApply: null,
                    onClose: null,
                    onCategory: (v) => setState(() => _category = v),
                    onStatus: (v) => setState(() => _status = v),
                    onPrice: (v) => setState(() => _priceRange = v),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    header,
                    Expanded(child: grid),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openFiltersSheet(BuildContext context) {
    final maxPrice = _maxPriceFor(ref.read(auctionsViewModelProvider));
    var tempCategory = _category;
    var tempStatus = _status;
    var tempPrice = RangeValues(
      _priceRange.start.clamp(0, maxPrice).toDouble(),
      _priceRange.end.clamp(0, maxPrice).toDouble(),
    );

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void resetTemp() {
              setSheetState(() {
                tempCategory = 'All';
                tempStatus = 'All';
                tempPrice = RangeValues(0, maxPrice);
              });
            }

            void apply() {
              setState(() {
                _category = tempCategory;
                _status = tempStatus;
                _priceRange = tempPrice;
              });
              Navigator.pop(context);
            }

            void close() {
              Navigator.pop(context);
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.80,
                  child: _FiltersPanel(
                    category: tempCategory,
                    status: tempStatus,
                    priceRange: tempPrice,
                    maxPrice: maxPrice,
                    isBottomSheet: true,
                    onReset: resetTemp,
                    onApply: apply,
                    onClose: close,
                    onCategory: (v) => setSheetState(() => tempCategory = v),
                    onStatus: (v) => setSheetState(() => tempStatus = v),
                    onPrice: (v) => setSheetState(() => tempPrice = v),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ListHero extends StatelessWidget {
  const _ListHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [EntryFlowTokens.backgroundTop, EntryFlowTokens.backgroundBottom],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Auction directory', 'دليل المزادات'),
            style: const TextStyle(
              color: EntryFlowTokens.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            context.tr(
              'Browse listings with a cleaner mobile flow',
              'تصفح المزادات بتجربة أوضح على الهاتف',
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 10),
          Text(
            context.tr(
              'Search, filter, and move through auctions with less visual noise and stronger phone-first spacing.',
              'ابحث وصفِّ وانتقل بين المزادات بتجربة أقل ازدحاماً وأكثر ملاءمة للهاتف.',
            ),
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;

  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _AuctionsGrid extends StatelessWidget {
  final bool loading;
  final String? error;
  final int itemsCount;
  final VoidCallback onRetry;
  final Widget child;

  const _AuctionsGrid({
    required this.loading,
    required this.error,
    required this.itemsCount,
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && itemsCount == 0) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (error != null && itemsCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: onRetry,
                child: Text(context.tr('Retry', 'إعادة المحاولة')),
              ),
            ],
          ),
        ),
      );
    }

    if (itemsCount == 0) {
      return Center(
        child: Text(
          context.tr(
            'No auctions match your filters.',
            'لا توجد مزادات تطابق الفلاتر الحالية.',
          ),
        ),
      );
    }

    return child;
  }
}

class _FiltersPanel extends StatefulWidget {
  final String category;
  final String status;
  final RangeValues priceRange;
  final double maxPrice;

  final ValueChanged<String> onCategory;
  final ValueChanged<String> onStatus;
  final ValueChanged<RangeValues> onPrice;

  final VoidCallback onReset;
  final VoidCallback? onApply;
  final VoidCallback? onClose;
  final bool isBottomSheet;

  const _FiltersPanel({
    required this.category,
    required this.status,
    required this.priceRange,
    required this.maxPrice,
    required this.onCategory,
    required this.onStatus,
    required this.onPrice,
    required this.onReset,
    required this.onApply,
    required this.onClose,
    required this.isBottomSheet,
  });

  @override
  State<_FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<_FiltersPanel> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

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
                const Icon(Icons.filter_alt_outlined),
                const SizedBox(width: 8),
                Text(
                  context.tr('Filters', 'الفلاتر'),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onReset,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(context.tr('Reset', 'إعادة تعيين')),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Expanded(
              child: Scrollbar(
                controller: _scrollCtrl,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Categories', 'الفئات'),
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      _PrettyRadio(
                        groupValue: widget.category,
                        value: 'All',
                        onChanged: widget.onCategory,
                      ),
                      _PrettyRadio(
                        groupValue: widget.category,
                        value: 'Vehicles',
                        onChanged: widget.onCategory,
                      ),
                      _PrettyRadio(
                        groupValue: widget.category,
                        value: 'Real Estate',
                        onChanged: widget.onCategory,
                      ),
                      _PrettyRadio(
                        groupValue: widget.category,
                        value: 'Electronics',
                        onChanged: widget.onCategory,
                      ),
                      _PrettyRadio(
                        groupValue: widget.category,
                        value: 'Industrial',
                        onChanged: widget.onCategory,
                      ),
                      _PrettyRadio(
                        groupValue: widget.category,
                        value: 'Jewelry',
                        onChanged: widget.onCategory,
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('Status', 'الحالة'),
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: widget.status,
                        items: [
                          DropdownMenuItem(
                            value: 'Active Auctions',
                            child: Text(context.tr('Active Auctions', 'مزادات نشطة')),
                          ),
                          DropdownMenuItem(
                            value: 'Ended',
                            child: Text(context.tr('Ended', 'منتهية')),
                          ),
                          DropdownMenuItem(
                            value: 'All',
                            child: Text(context.tr('All', 'الكل')),
                          ),
                        ],
                        onChanged: (v) => widget.onStatus(v ?? 'All'),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            context.tr('Price Range', 'نطاق السعر'),
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const Spacer(),
                          Text(
                            '${context.l10n.t('EGP', 'ج.م')} ${widget.priceRange.start.toStringAsFixed(0)} - ${widget.priceRange.end.toStringAsFixed(0)}',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                      RangeSlider(
                        min: 0,
                        max: widget.maxPrice,
                        values: widget.priceRange,
                        onChanged: widget.onPrice,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.isBottomSheet) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(context.tr('Close', 'إغلاق')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: widget.onApply,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(context.tr('Apply', 'تطبيق')),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrettyRadio extends StatelessWidget {
  final String groupValue;
  final String value;
  final ValueChanged<String> onChanged;

  const _PrettyRadio({
    required this.groupValue,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = groupValue == value;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? cs.primary : cs.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                switch (value) {
                  'All' => context.tr('All', 'الكل'),
                  'Vehicles' => context.tr('Vehicles', 'مركبات'),
                  'Real Estate' => context.tr('Real Estate', 'عقارات'),
                  'Electronics' => context.tr('Electronics', 'إلكترونيات'),
                  'Industrial' => context.tr('Industrial', 'صناعي'),
                  'Jewelry' => context.tr('Jewelry', 'مجوهرات'),
                  _ => value,
                },
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
