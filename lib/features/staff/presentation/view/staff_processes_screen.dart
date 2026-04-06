import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

class StaffProcessesScreen extends StatefulWidget {
  const StaffProcessesScreen({super.key});

  @override
  State<StaffProcessesScreen> createState() => _StaffProcessesScreenState();
}

class _StaffProcessesScreenState extends State<StaffProcessesScreen> {
  String _type = 'All';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final all = _mockProcesses();
    final items = all.where((p) {
      if (_type == 'All') return true;
      return p.type.toLowerCase() == _type.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Staff Processes', 'عمليات الموظفين')),
        leading: IconButton(
          tooltip: context.tr('Back', 'رجوع'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home'); // fallback
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Create (placeholder)', 'إنشاء (تجريبي)'),
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _toast(
              context,
              context.tr('Create process (placeholder)', 'إنشاء عملية (تجريبي)'),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B3C8C), Color(0xFF0A2F6E)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.rule_folder_outlined,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(
                      'Manage Auction/Tender processes.\nTrack lifecycle, items, and approvals.',
                      'إدارة عمليات المزادات والمناقصات.\nتابع دورة الحياة والعناصر والموافقات.',
                    ),
                    style: TextStyle(color: Colors.white70, height: 1.25),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _type,
                      items: [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text(context.tr('All', 'الكل')),
                        ),
                        DropdownMenuItem(
                          value: 'Auction',
                          child: Text(context.tr('Auction', 'مزاد')),
                        ),
                        DropdownMenuItem(
                          value: 'Tender',
                          child: Text(context.tr('Tender', 'مناقصة')),
                        ),
                      ],
                      onChanged: (v) => setState(() => _type = v ?? 'All'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _EmptyState(
              title: context.tr('No processes found', 'لا توجد عمليات'),
              subtitle: context.tr(
                'Try changing the type filter or create a new process.',
                'جرّب تغيير نوع التصفية أو إنشاء عملية جديدة.',
              ),
              icon: Icons.find_in_page_outlined,
            )
          else
            ...items.map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _toast(
                    context,
                    context.tr(
                      'Open process #${p.id} (placeholder)',
                      'فتح العملية #${p.id} (تجريبي)',
                    ),
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Tag(
                                text: p.type.toUpperCase(),
                                bg: primary.withOpacity(.10),
                                fg: primary,
                              ),
                              const SizedBox(width: 8),
                              _Status(status: p.status),
                              const Spacer(),
                              Text(
                                context.tr('ID #${p.id}', 'المعرف #${p.id}'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.meta,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _toast(
                                    context,
                                    context.tr('Edit (placeholder)', 'تعديل (تجريبي)'),
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: Text(context.tr('Edit', 'تعديل')),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _toast(
                                    context,
                                    context.tr(
                                      'View approvals (placeholder)',
                                      'عرض الموافقات (تجريبي)',
                                    ),
                                  ),
                                  icon: const Icon(Icons.approval_outlined),
                                  label: Text(context.tr('Approvals', 'الموافقات')),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _Status extends StatelessWidget {
  final String status;
  const _Status({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;

    switch (status) {
      case 'active':
        bg = const Color(0xFFEAF2FF);
        fg = const Color(0xFF0B3C8C);
        break;
      case 'closed':
        bg = const Color(0xFFF2F2F2);
        fg = Colors.black54;
        break;
      case 'draft':
      default:
        bg = const Color(0xFFFFF4D6);
        fg = const Color(0xFF7A5D00);
        break;
    }

    return _Tag(
      text: context.tr(status.toUpperCase(), _statusArabic(status)),
      bg: bg,
      fg: fg,
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Tag({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: fg),
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
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ProcessItem {
  final String id;
  final String type; // Auction/Tender
  final String status; // draft/active/closed
  final String title;
  final String meta;

  _ProcessItem({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.meta,
  });
}

List<_ProcessItem> _mockProcesses() {
  return [
    _ProcessItem(
      id: '112',
      type: 'Auction',
      status: 'active',
      title: 'Vehicles Lot • Cairo',
      meta: 'Start: 2026-02-01 • End: 2026-02-10 • Min: EGP 250,000',
    ),
    _ProcessItem(
      id: '118',
      type: 'Tender',
      status: 'draft',
      title: 'IT Network Equipment • Alexandria',
      meta: 'Start: 2026-02-05 • End: 2026-02-18 • Min: EGP 1,200,000',
    ),
    _ProcessItem(
      id: '097',
      type: 'Auction',
      status: 'closed',
      title: 'Real Estate • Giza',
      meta: 'Ended • Winner selected • Order created',
    ),
    _ProcessItem(
      id: '105',
      type: 'Tender',
      status: 'active',
      title: 'Industrial Tools Lot • Suez',
      meta: 'Approvals in progress • 3 items • Min: EGP 820,000',
    ),
  ];
}

String _statusArabic(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return 'نشط';
    case 'closed':
      return 'مغلق';
    case 'draft':
      return 'مسودة';
    default:
      return status;
  }
}
