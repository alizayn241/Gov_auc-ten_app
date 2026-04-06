import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/app_notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<_NotificationItem> _items = const [];

  final _service = AppNotificationsService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _service.listNotificationsForCurrentUser();
      if (!mounted) return;
      setState(() {
        _items = rows.map(_NotificationItem.fromMap).toList();
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

  Future<void> _openItem(_NotificationItem item) async {
    if (item.id.isNotEmpty && item.readAt == null) {
      try {
        await _service.markNotificationAsRead(item.id);
      } catch (_) {}
    }

    final route = item.targetRoute;
    if (route == null || route.isEmpty) {
      await _load();
      return;
    }

    if (!mounted) return;
    await context.push(route);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Notifications', 'الإشعارات')),
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
                        const SizedBox(height: 12),
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
                      const _EmptyState()
                    else
                      ..._items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _NotificationCard(
                            item: item,
                            onTap: item.targetRoute == null && item.id.isEmpty
                                ? null
                                : () => _openItem(item),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;
  final VoidCallback? onTap;

  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                        if (item.readAt == null)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.createdLabel,
                      style: TextStyle(
                        color: item.readAt == null
                            ? item.color
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: item.readAt == null
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 10),
                  child: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
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
              child: Icon(
                Icons.notifications_none_outlined,
                color: primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('No notifications yet', 'لا توجد إشعارات بعد'),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'New auctions and tenders will appear here when they are added by the admin team.',
                'ستظهر هنا المزادات والمناقصات الجديدة عند إضافتها من قبل فريق الإدارة.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final String entityType;
  final String entityId;
  final DateTime? createdAt;
  final DateTime? readAt;

  const _NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    required this.readAt,
  });

  factory _NotificationItem.fromMap(Map<String, dynamic> map) {
    return _NotificationItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      entityType: (map['entity_type'] ?? '').toString(),
      entityId: (map['entity_id'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString())
          ?.toLocal(),
      readAt: DateTime.tryParse((map['read_at'] ?? '').toString())?.toLocal(),
    );
  }

  String? get targetRoute {
    if (entityType == 'auction' && entityId.isNotEmpty) {
      return '/auction/$entityId';
    }
    if (entityType == 'tender' && entityId.isNotEmpty) {
      return '/tender/$entityId';
    }
    return null;
  }

  IconData get icon {
    if (entityType == 'tender') return Icons.request_quote_outlined;
    return Icons.gavel_outlined;
  }

  Color get color {
    if (entityType == 'tender') return const Color(0xFF0B6E4F);
    return const Color(0xFF0B3C8C);
  }

  String get createdLabel {
    final value = createdAt;
    if (value == null) return '-';
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$mm-$dd $hh:$min';
  }
}
