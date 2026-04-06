import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

class StaffApprovalsScreen extends StatefulWidget {
  const StaffApprovalsScreen({super.key});

  @override
  State<StaffApprovalsScreen> createState() => _StaffApprovalsScreenState();
}

class _StaffApprovalsScreenState extends State<StaffApprovalsScreen> {
  String _filter = 'Pending';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final items = _mockApprovals().where((a) {
      if (_filter == 'All') return true;
      return a.status == _filter.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Staff Approvals', 'موافقات الموظفين')),
        leading: IconButton(
          tooltip: context.tr('Back', 'رجوع'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // context.go('/home'); // fallback
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(
            title: context.tr('Approvals Queue', 'قائمة الموافقات'),
            subtitle: context.tr(
              'Review and approve/reject processes. All decisions are logged for transparency.',
              'راجع العمليات ووافق أو ارفض. يتم تسجيل جميع القرارات من أجل الشفافية.',
            ),
            right: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filter,
                items: [
                  DropdownMenuItem(value: 'Pending', child: Text(context.tr('Pending', 'معلق'))),
                  DropdownMenuItem(value: 'Approved', child: Text(context.tr('Approved', 'مقبول'))),
                  DropdownMenuItem(value: 'Rejected', child: Text(context.tr('Rejected', 'مرفوض'))),
                  DropdownMenuItem(value: 'All', child: Text(context.tr('All', 'الكل'))),
                ],
                onChanged: (v) => setState(() => _filter = v ?? 'Pending'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _EmptyState(
              title: context.tr('No approvals here', 'لا توجد موافقات هنا'),
              subtitle: context.tr(
                'Try changing the filter or check back later.',
                'جرّب تغيير التصفية أو عد لاحقاً.',
              ),
              icon: Icons.inbox_outlined,
            )
          else
            ...items.map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Tag(
                              text: a.type.toUpperCase(),
                              bg: primary.withOpacity(.10),
                              fg: primary,
                            ),
                            const SizedBox(width: 8),
                            _StatusPill(status: a.status),
                            const Spacer(),
                            Text(
                              a.date,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          a.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a.subtitle,
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
                                onPressed: a.status == 'pending'
                                    ? () => _toast(
                                        context, context.tr('Rejected (placeholder)', 'تم الرفض (تجريبي)'))
                                    : null,
                                icon: const Icon(Icons.close),
                                label: Text(context.tr('Reject', 'رفض')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: a.status == 'pending'
                                    ? () => _toast(
                                        context, context.tr('Approved (placeholder)', 'تمت الموافقة (تجريبي)'))
                                    : null,
                                icon: const Icon(Icons.check),
                                label: Text(context.tr('Approve', 'موافقة')),
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget right;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3C8C), Color(0xFF0A2F6E)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.approval, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    )),
                const SizedBox(height: 6),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white70, height: 1.25)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: right,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;

    switch (status) {
      case 'approved':
        bg = const Color(0xFFE8F7EE);
        fg = const Color(0xFF027A48);
        break;
      case 'rejected':
        bg = const Color(0xFFFFE8E8);
        fg = const Color(0xFFB42318);
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFFF4D6);
        fg = const Color(0xFF7A5D00);
        break;
    }

    return _Tag(
      text: context.tr(status.toUpperCase(), _approvalStatusArabic(status)),
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

class _ApprovalItem {
  final String type; // auction / tender
  final String status; // pending/approved/rejected
  final String title;
  final String subtitle;
  final String date;

  _ApprovalItem({
    required this.type,
    required this.status,
    required this.title,
    required this.subtitle,
    required this.date,
  });
}

List<_ApprovalItem> _mockApprovals() {
  return [
    _ApprovalItem(
      type: 'Auction',
      status: 'pending',
      title: 'Auction: Vehicles Lot #112',
      subtitle: 'Transport Authority • Cairo • Minimum price EGP 250,000',
      date: 'Today',
    ),
    _ApprovalItem(
      type: 'Tender',
      status: 'pending',
      title: 'Tender: IT Network Equipment',
      subtitle: 'IT Department • Alexandria • Min price EGP 1,200,000',
      date: 'Today',
    ),
    _ApprovalItem(
      type: 'Auction',
      status: 'approved',
      title: 'Auction: Real Estate Ref #88',
      subtitle: 'Housing Authority • Giza • Min price EGP 3,500,000',
      date: 'Yesterday',
    ),
    _ApprovalItem(
      type: 'Tender',
      status: 'rejected',
      title: 'Tender: Industrial Tools Lot',
      subtitle: 'Public Works • Suez • Missing documentation',
      date: '2 days ago',
    ),
  ];
}

String _approvalStatusArabic(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return 'مقبول';
    case 'rejected':
      return 'مرفوض';
    case 'pending':
      return 'معلق';
    default:
      return status;
  }
}
