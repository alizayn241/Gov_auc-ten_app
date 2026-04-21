import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auctions/data/sources/auctions_admin_remote_data_source.dart';
import 'processes/processes_app_bar.dart';
import 'processes/processes_cards.dart';
import 'processes/processes_filters.dart';
import 'processes/processes_hero.dart';
import 'processes/processes_models.dart';
import 'shared/admin_shared.dart';

class AdminProcessesScreen extends StatefulWidget {
  const AdminProcessesScreen({super.key});

  @override
  State<AdminProcessesScreen> createState() => _AdminProcessesScreenState();
}

class _AdminProcessesScreenState extends State<AdminProcessesScreen>
    with SingleTickerProviderStateMixin {
  String _type = 'All';
  String _lifecycle = 'Active';
  String _creator = 'All';

  bool _loading = true;
  String? _error;
  List<AdminProcessItem> _items = const [];

  late final AuctionsAdminRemoteDataSource _remote;
  late final AnimationController _animCtrl;
  late final Animation<double> _heroAnim;
  late final Animation<double> _bodyAnim;

  @override
  void initState() {
    super.initState();
    _remote = AuctionsAdminRemoteDataSource(Supabase.instance.client);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _bodyAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sb = Supabase.instance.client;
      final results = await Future.wait([
        sb
            .from('auctions')
            .select(
              'id,title,category,start_price,start_date,end_time,status,created_by,created_at',
            )
            .order('created_at', ascending: false),
        sb
            .from('tenders')
            .select('id,title,entity,status,submission_deadline,created_at')
            .order('created_at', ascending: false),
        sb.from('profiles').select('*'),
      ]);

      final profileRows = (results[2] as List)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();
      final profileMap = {
        for (final row in profileRows)
          (row['id'] ?? '').toString(): AdminProfileMini.fromMap(row),
      };

      final auctions = (results[0] as List)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .map((row) => AdminProcessItem.fromAuction(row, profileMap))
          .toList();

      final tenders = (results[1] as List)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .map(AdminProcessItem.fromTender)
          .toList();

      if (!mounted) return;

      setState(() {
        _items = [...auctions, ...tenders]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _publishAuction(AdminProcessItem item) async {
    if (item.type != 'Auction') return;

    setState(() => _loading = true);
    try {
      await _remote.publishAuction(item.id);
      await _load();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Auction "${item.title}" published',
              'تم نشر المزاد "${item.title}"',
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<AdminProcessItem> get _filtered {
    return _items.where((process) {
      if (_type != 'All' && process.type != _type) return false;
      if (_lifecycle == 'Active' && process.isCompleted) return false;
      if (_lifecycle == 'Completed' && !process.isCompleted) return false;
      if (_creator == 'Staff only' &&
          process.creatorRole.toLowerCase() != 'staff') {
        return false;
      }
      return true;
    }).toList();
  }

  int get _auctionCount => _items.where((process) => process.type == 'Auction').length;
  int get _tenderCount => _items.where((process) => process.type == 'Tender').length;
  int get _pendingCount => _items.where((process) => process.canPublish).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: ProcessesAppBar(
              onBack: () => context.canPop() ? context.pop() : context.go('/home'),
              onRefresh: _load,
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _heroAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ).animate(_heroAnim),
                child: ProcessesHero(
                  auctionCount: _auctionCount,
                  tenderCount: _tenderCount,
                  pendingCount: _pendingCount,
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
                    const SizedBox(height: 16),
                    ProcessesFilterChips(
                      type: _type,
                      lifecycle: _lifecycle,
                      creator: _creator,
                      onType: (value) => setState(() => _type = value),
                      onLifecycle: (value) => setState(() => _lifecycle = value),
                      onCreator: (value) => setState(() => _creator = value),
                    ),
                    const SizedBox(height: 10),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_error != null)
                      AdminErrorCard(message: _error!, onRetry: _load)
                    else if (filtered.isEmpty)
                      AdminEmptyCard(
                        icon: Icons.find_in_page_rounded,
                        title: context.tr('No processes found', 'لا توجد عمليات'),
                        subtitle: context.tr(
                          'Try adjusting the filters above.',
                          'جرّب تغيير عوامل التصفية أعلاه.',
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          context.tr(
                            '${filtered.length} processes',
                            '${filtered.length} عملية',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                      ...filtered.map((process) {
                        return ProcessCard(
                          process: process,
                          onPublish: process.type == 'Auction' && process.canPublish
                              ? () => _publishAuction(process)
                              : null,
                          onManage: process.type == 'Auction' && !process.isCompleted
                              ? () => context.push('/admin/auctions/${process.id}/manage')
                              : null,
                          onOpen: process.type == 'Tender'
                              ? () => context.push('/admin/tenders/${process.id}/award')
                              : null,
                          onParticipants: process.type == 'Auction'
                              ? () => context.push('/admin/auctions/${process.id}/participants')
                              : null,
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
