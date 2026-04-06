import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auctions/data/sources/auctions_admin_remote_data_source.dart';

class AdminProcessesScreen extends StatefulWidget {
  const AdminProcessesScreen({super.key});

  @override
  State<AdminProcessesScreen> createState() => _AdminProcessesScreenState();
}

class _AdminProcessesScreenState extends State<AdminProcessesScreen> {
  String _type = 'All';
  String _creatorFilter = 'All';

  bool _loading = true;
  String? _error;
  List<_ProcessItem> _items = const [];

  late final AuctionsAdminRemoteDataSource _remote;

  @override
  void initState() {
    super.initState();
    _remote = AuctionsAdminRemoteDataSource(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('auctions')
            .select(
              'id,title,category,start_price,start_date,end_time,status,created_by,created_at',
            )
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('tenders')
            .select('id,title,entity,status,submission_deadline,created_at')
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('profiles')
            .select('*'),
      ]);

      final profileRows = (results[2] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final profileMap = {
        for (final row in profileRows)
          (row['id'] ?? '').toString(): _ProfileMini.fromMap(row),
      };

      final auctionItems = (results[0] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((row) => _ProcessItem.fromAuction(row, profileMap))
          .toList();

      final tenderItems = (results[1] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map(_ProcessItem.fromTender)
          .toList();

      if (!mounted) return;
      setState(() {
        _items = [...auctionItems, ...tenderItems]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  Future<void> _publishAuction(_ProcessItem item) async {
    if (item.type != 'Auction') return;

    setState(() => _loading = true);
    try {
      await _remote.publishAuction(item.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('Auction "${item.title}" published', 'تم نشر المزاد "${item.title}"'),
          ),
        ),
      );
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
    final filtered = _items.where((p) {
      if (_type != 'All' && p.type != _type) return false;
      if (_creatorFilter == 'Staff only' &&
          p.creatorRole.toLowerCase() != 'staff') {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Processes', 'العمليات')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FiltersBar(
            type: _type,
            creatorFilter: _creatorFilter,
            onTypeChanged: (v) => setState(() => _type = v),
            onCreatorChanged: (v) => setState(() => _creatorFilter = v),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_error != null)
            _ErrorCard(message: _error!, onRetry: _load)
          else if (filtered.isEmpty)
            _EmptyState(
              title: context.tr('No processes found', 'لا توجد عمليات'),
              subtitle: context.tr(
                'Create an auction or change the filters.',
                'أنشئ مزاداً أو غيّر عوامل التصفية.',
              ),
              icon: Icons.find_in_page_outlined,
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${filtered.length} processes',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            ...filtered.map(
              (p) => _ProcessCard(
                p: p,
                onPublish: p.type == 'Auction' && p.canPublish
                    ? () => _publishAuction(p)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final String type;
  final String creatorFilter;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onCreatorChanged;

  const _FiltersBar({
    required this.type,
    required this.creatorFilter,
    required this.onTypeChanged,
    required this.onCreatorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          runSpacing: 10,
          spacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 8),
                const Text('Type:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Auction', child: Text('Auction')),
                    DropdownMenuItem(value: 'Tender', child: Text('Tender')),
                  ],
                  onChanged: (v) => onTypeChanged(v ?? 'All'),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Creator:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: creatorFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(
                      value: 'Staff only',
                      child: Text('Staff only'),
                    ),
                  ],
                  onChanged: (v) => onCreatorChanged(v ?? 'All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessCard extends StatelessWidget {
  final _ProcessItem p;
  final VoidCallback? onPublish;

  const _ProcessCard({required this.p, required this.onPublish});

  void _openPrimary(BuildContext context) {
    if (p.type == 'Tender') {
      context.push('/admin/tenders/${p.id}/award');
      return;
    }
    context.push('/admin/auctions/${p.id}/manage');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(text: p.type, kind: 'type'),
                        _Chip(text: p.statusLabel, kind: 'status'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '#${p.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                p.title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                p.meta,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'Created by: ${p.creatorLabel}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 150,
                    child: OutlinedButton.icon(
                      onPressed: () => _openPrimary(context),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(p.type == 'Auction' ? 'Manage' : 'Open'),
                    ),
                  ),
                  if (p.type == 'Auction')
                    SizedBox(
                      width: 170,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/admin/auctions/${p.id}/participants'),
                        icon: const Icon(Icons.how_to_reg_outlined),
                        label: Text(context.tr('Review Participants', 'مراجعة المشاركين')),
                      ),
                    ),
                  if (onPublish != null)
                    SizedBox(
                      width: 130,
                      child: FilledButton.icon(
                        onPressed: onPublish,
                        icon: const Icon(Icons.publish_outlined),
                        label: Text(context.tr('Confirm', 'تأكيد')),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final String kind;

  const _Chip({required this.text, required this.kind});

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final cs = Theme.of(context).colorScheme;
    final color = switch (kind) {
      'type' => const Color(0xFF0B3C8C),
      _ when lower == 'draft' => const Color(0xFF7A5D00),
      _ when lower == 'published' || lower == 'active' => Colors.green,
      _ when lower == 'ended' || lower == 'closed' => cs.onSurfaceVariant,
      _ => Colors.deepOrange,
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

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('Retry', 'إعادة المحاولة')),
            ),
          ],
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
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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

class _ProfileMini {
  final String name;
  final String email;
  final String role;

  const _ProfileMini({
    required this.name,
    required this.email,
    required this.role,
  });

  factory _ProfileMini.fromMap(Map<String, dynamic> map) {
    final resolvedName = _firstNonEmpty([
      map['display_name'],
      map['name'],
      map['full_name'],
      map['username'],
      map['id'],
    ]);

    return _ProfileMini(
      name: resolvedName,
      email: '',
      role: (map['role'] ?? 'citizen').toString(),
    );
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

class _ProcessItem {
  final String id;
  final String type;
  final String status;
  final String title;
  final String meta;
  final DateTime createdAt;
  final String creatorLabel;
  final String creatorRole;

  const _ProcessItem({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.meta,
    required this.createdAt,
    required this.creatorLabel,
    required this.creatorRole,
  });

  factory _ProcessItem.fromAuction(
    Map<String, dynamic> map,
    Map<String, _ProfileMini> profiles,
  ) {
    final creatorId = (map['created_by'] ?? '').toString();
    final creator = profiles[creatorId];
    final startDate = _fmtDate(map['start_date']);
    final endDate = _fmtDate(map['end_time']);
    final category = (map['category'] ?? 'Other').toString();
    final price = _toDouble(map['start_price']).toStringAsFixed(0);

    return _ProcessItem(
      id: (map['id'] ?? '').toString(),
      type: 'Auction',
      status: (map['status'] ?? 'draft').toString(),
      title: (map['title'] ?? '').toString(),
      meta: '$category • Start: $startDate • End: $endDate • Min: EGP $price',
      createdAt: _parseDate(map['created_at']),
      creatorLabel: creator == null
          ? 'Unknown user'
          : (creator.name.isEmpty ? 'Unknown user' : creator.name),
      creatorRole: creator?.role ?? '',
    );
  }

  factory _ProcessItem.fromTender(Map<String, dynamic> map) {
    final deadline = _fmtDate(map['submission_deadline']);
    return _ProcessItem(
      id: (map['id'] ?? '').toString(),
      type: 'Tender',
      status: (map['status'] ?? 'draft').toString(),
      title: (map['title'] ?? '').toString(),
      meta: '${(map['entity'] ?? 'Government').toString()} • Deadline: $deadline',
      createdAt: _parseDate(map['created_at']),
      creatorLabel: 'Tender workflow',
      creatorRole: '',
    );
  }

  String get statusLabel => status.isEmpty ? 'draft' : status;

  bool get canPublish {
    final lower = status.toLowerCase();
    return lower == 'draft' || lower == 'pending';
  }

  static DateTime _parseDate(dynamic value) {
    return DateTime.tryParse((value ?? '').toString())?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _fmtDate(dynamic value) {
    final d = DateTime.tryParse((value ?? '').toString())?.toLocal();
    if (d == null) return '-';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd $hh:$min';
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }
}
