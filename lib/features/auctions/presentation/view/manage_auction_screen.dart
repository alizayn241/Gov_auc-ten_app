import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/app_notifications_service.dart';
import '../../data/models/admin_invoice_item.dart';
import '../../data/sources/auctions_admin_remote_data_source.dart';
import 'auction_location_picker_screen.dart';
import '../viewmodel/auctions_view_model.dart';

class ManageAuctionScreen extends ConsumerStatefulWidget {
  final String auctionId;
  const ManageAuctionScreen({super.key, required this.auctionId});

  @override
  ConsumerState<ManageAuctionScreen> createState() =>
      _ManageAuctionScreenState();
}

class _ManageAuctionScreenState extends ConsumerState<ManageAuctionScreen> {
  final _title = TextEditingController();
  final _startPrice = TextEditingController();
  final _location = TextEditingController();

  String? _category;
  DateTime? _startDate;
  DateTime? _endTime;
  double? _latitude;
  double? _longitude;
  String _status = 'draft';
  AdminInvoiceItem? _invoice;

  bool loading = true;
  String? error;

  final _remote = AuctionsAdminRemoteDataSource(Supabase.instance.client);
  final _notifications = AppNotificationsService(Supabase.instance.client);

  static const List<String> auctionCategories = [
    'Vehicles',
    'Real Estate',
    'Electronics',
    'Industrial',
    'Jewelry',
    'Furniture',
    'Machinery',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _startPrice.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final row = await Supabase.instance.client
          .from('auctions')
          .select('*')
          .eq('id', widget.auctionId)
          .single();

      final invoice = await _remote.getInvoiceByAuction(widget.auctionId);

      _title.text = (row['title'] ?? '').toString();
      _category = (row['category'] ?? '').toString().isEmpty
          ? null
          : (row['category'] ?? '').toString();
      _startPrice.text = (row['start_price'] ?? '').toString();
      _location.text = (row['location'] ?? '').toString();
      _latitude = (row['latitude'] as num?)?.toDouble();
      _longitude = (row['longitude'] as num?)?.toDouble();
      _status = (row['status'] ?? 'draft').toString();
      _startDate = DateTime.tryParse(row['start_date'].toString());
      _endTime = DateTime.tryParse(row['end_time'].toString());
      _invoice = invoice;

      setState(() => loading = false);
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _pickStart() async {
    final base = _startDate ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: base,
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (t == null) return;

    setState(() {
      _startDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _pickEnd() async {
    final base = _endTime ?? DateTime.now().add(const Duration(days: 7));
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: base,
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (t == null) return;

    setState(() {
      _endTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _pickLocation() async {
    final selected = await Navigator.of(context).push<AuctionLocationSelection>(
      MaterialPageRoute(
        builder: (_) => AuctionLocationPickerScreen(
          initialLabel: _location.text.trim(),
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (selected == null) return;

    setState(() {
      _location.text = selected.label;
      _latitude = selected.latitude;
      _longitude = selected.longitude;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final category = _category;
    final startPrice = num.tryParse(_startPrice.text.trim());
    final location = _location.text.trim();

    if (title.isEmpty ||
        category == null ||
        startPrice == null ||
        _startDate == null ||
        _endTime == null) {
      setState(
        () => error = context.tr(
          'Please complete all fields',
          'يرجى إكمال جميع الحقول',
        ),
      );
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await _remote.updateAuction(
        auctionId: widget.auctionId,
        title: title,
        category: category,
        startPrice: startPrice,
        startDate: _startDate!,
        endTime: _endTime!,
        location: location,
        latitude: _latitude,
        longitude: _longitude,
      );

      await _load();
      await ref.read(auctionsViewModelProvider.notifier).refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Auction updated', 'تم تحديث المزاد'))),
      );
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _publish() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await _remote.publishAuction(widget.auctionId);

      try {
        await _notifications.createAuctionCreatedNotification(
          auctionId: widget.auctionId,
          title: _title.text.trim(),
          category: (_category ?? '').trim().isEmpty ? 'Other' : _category!.trim(),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Auction published, but notification creation failed: ${e.toString().replaceFirst('Exception: ', '')}',
                'تم نشر المزاد، لكن فشل إنشاء الإشعار: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
            ),
          ),
        );
      }

      await _load();
      await ref.read(auctionsViewModelProvider.notifier).refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Auction published', 'تم نشر المزاد'))),
      );
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _fmt(DateTime? d) => d == null ? '-' : d.toLocal().toString();

  bool get _canEditCoreFields =>
      {'draft', 'published', 'suspended'}.contains(_status.toLowerCase());

  bool get _canPublish => _status.toLowerCase() == 'draft';

  bool get _canReviewParticipants =>
      {'published', 'active', 'live', 'ended', 'awaiting_payment', 'paid'}
          .contains(_status.toLowerCase());

  bool get _canFinalize =>
      {'ended', 'active', 'live'}.contains(_status.toLowerCase());

  bool get _canConfirmPayment =>
      _invoice != null &&
      !_isInvoicePaid &&
      {'awaiting_payment', 'paid', 'ended', 'active', 'live'}
          .contains(_status.toLowerCase());

  bool get _isInvoicePaid =>
      (_invoice?.status ?? '').toLowerCase() == 'paid';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (loading && _title.text.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        title: Text(context.tr('Manage Auction', 'إدارة المزاد')),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh', 'تحديث'),
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LifecycleHero(
            auctionId: widget.auctionId,
            status: _status,
            invoice: _invoice,
          ),
          const SizedBox(height: 14),
          _StageTimeline(status: _status, invoice: _invoice),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Auction Details', 'تفاصيل المزاد'),
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _title,
                    enabled: _canEditCoreFields && !loading,
                    decoration: InputDecoration(
                      labelText: context.tr('Title', 'العنوان'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: InputDecoration(
                      labelText: context.tr('Category', 'الفئة'),
                      border: OutlineInputBorder(),
                    ),
                    items: auctionCategories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(context.tr(c, _localizeCategory(c))),
                          ),
                        )
                        .toList(),
                    onChanged: !_canEditCoreFields || loading
                        ? null
                        : (value) {
                            setState(() => _category = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _startPrice,
                    enabled: _canEditCoreFields && !loading,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: context.tr('Start Price', 'سعر البداية'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _location,
                    readOnly: true,
                    enabled: _canEditCoreFields && !loading,
                    decoration: InputDecoration(
                      labelText: context.tr('Auction Location', 'موقع المزاد'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      suffixIcon: IconButton(
                        onPressed: !_canEditCoreFields || loading ? null : _pickLocation,
                        icon: const Icon(Icons.map_outlined),
                      ),
                    ),
                    onTap: !_canEditCoreFields || loading ? null : _pickLocation,
                  ),
                  const SizedBox(height: 10),
                  if (_latitude != null && _longitude != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text(
                        context.tr(
                          'Coordinates: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                          'الإحداثيات: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      title: Text(context.tr('Start Date', 'تاريخ البدء')),
                      subtitle: Text(_fmt(_startDate)),
                      trailing: const Icon(Icons.date_range),
                      onTap: !_canEditCoreFields || loading ? null : _pickStart,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      title: Text(context.tr('End Time', 'وقت الانتهاء')),
                      subtitle: Text(_fmt(_endTime)),
                      trailing: const Icon(Icons.schedule),
                      onTap: !_canEditCoreFields || loading ? null : _pickEnd,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              !_canEditCoreFields || loading ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(context.l10n.save),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: !_canPublish || loading ? null : _publish,
                          icon: const Icon(Icons.publish_outlined),
                          label: Text(context.tr('Publish', 'نشر')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                    context.tr('Workflow Actions', 'إجراءات سير العمل'),
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    enabled: true,
                    icon: Icons.folder_outlined,
                    label: context.tr('Documents', 'المستندات'),
                    subtitle: context.tr(
                      'Upload and review auction documentation',
                      'رفع ومراجعة مستندات المزاد',
                    ),
                    onTap: () => context.push(
                      '/admin/auctions/${widget.auctionId}/documents',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    enabled: _canReviewParticipants,
                    icon: Icons.how_to_reg_outlined,
                    label: context.tr('Participants Review', 'مراجعة المشاركين'),
                    subtitle: context.tr(
                      'Approve or reject participant eligibility',
                      'قبول أو رفض أهلية المشاركين',
                    ),
                    onTap: () => context.push(
                      '/admin/auctions/${widget.auctionId}/participants',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    enabled: _canFinalize,
                    icon: Icons.emoji_events_outlined,
                    label: context.tr('Finalize Auction', 'إنهاء المزاد'),
                    subtitle: context.tr(
                      'Select the winner and generate the invoice',
                      'اختيار الفائز وإنشاء الفاتورة',
                    ),
                    onTap: () => context.push(
                      '/admin/auctions/${widget.auctionId}/finalize',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    enabled: _canConfirmPayment,
                    icon: Icons.payments_outlined,
                    label: _isInvoicePaid
                        ? context.tr('Payment Confirmed', 'تم تأكيد الدفع')
                        : context.tr('Confirm Payment', 'تأكيد الدفع'),
                    subtitle: _invoice == null
                        ? context.tr(
                            'Finalize the auction first to create an invoice',
                            'قم بإنهاء المزاد أولاً لإنشاء فاتورة',
                          )
                        : _isInvoicePaid
                            ? context.tr(
                                'The invoice is already marked as paid',
                                'تم تعليم الفاتورة كمدفوعة بالفعل',
                              )
                            : context.tr(
                                'Review the invoice and record the received payment',
                                'راجع الفاتورة وسجل الدفعة المستلمة',
                              ),
                    onTap: () => context.push(
                      '/admin/auctions/${widget.auctionId}/payment',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}

class _LifecycleHero extends StatelessWidget {
  final String auctionId;
  final String status;
  final AdminInvoiceItem? invoice;

  const _LifecycleHero({
    required this.auctionId,
    required this.status,
    required this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _statusLabel(status);
    final isPaid = (invoice?.status ?? '').toLowerCase() == 'paid';

    return Container(
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Auction Lifecycle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              _Pill(
                text: badge,
                bg: Colors.white,
                fg: const Color(0xFF0B3C8C),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Auction ID: $auctionId',
            style: TextStyle(color: Colors.white.withOpacity(.85)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(
                label: 'Status',
                value: badge,
              ),
              _HeroMetric(
                label: 'Invoice',
                value: invoice == null ? 'Not created' : invoice!.status,
              ),
              _HeroMetric(
                label: 'Payment',
                value: invoice == null
                    ? 'N/A'
                    : isPaid
                        ? 'Paid'
                        : 'Awaiting',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(.74),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageTimeline extends StatelessWidget {
  final String status;
  final AdminInvoiceItem? invoice;

  const _StageTimeline({required this.status, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lower = status.toLowerCase();
    final paid = (invoice?.status ?? '').toLowerCase() == 'paid';

    final stages = <_StageItem>[
      _StageItem('Draft', lower == 'draft'),
      _StageItem('Published', {'published', 'active', 'live', 'ended', 'awaiting_payment', 'paid'}
          .contains(lower)),
      _StageItem('In Progress', {'active', 'live', 'ended', 'awaiting_payment', 'paid'}
          .contains(lower)),
      _StageItem('Finalized', {'ended', 'awaiting_payment', 'paid'}.contains(lower)),
      _StageItem('Paid', paid),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lifecycle Stage',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: stages
                  .map((stage) => _Pill(
                        text: stage.label,
                        bg: stage.active
                            ? cs.primary.withOpacity(.12)
                            : cs.surfaceContainerHighest,
                        fg: stage.active
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageItem {
  final String label;
  final bool active;

  const _StageItem(this.label, this.active);
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Pill({
    required this.text,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool enabled;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.enabled,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : .55,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'draft':
      return 'Draft';
    case 'published':
      return 'Published';
    case 'active':
      return 'Active';
    case 'live':
      return 'Live';
    case 'ended':
      return 'Ended';
    case 'awaiting_payment':
      return 'Awaiting Payment';
    case 'paid':
      return 'Paid';
    case 'cancelled':
      return 'Cancelled';
    case 'suspended':
      return 'Suspended';
    default:
      return status;
  }
}

String _localizeCategory(String category) {
  switch (category) {
    case 'Vehicles':
      return 'مركبات';
    case 'Real Estate':
      return 'عقارات';
    case 'Electronics':
      return 'إلكترونيات';
    case 'Industrial':
      return 'صناعي';
    case 'Jewelry':
      return 'مجوهرات';
    case 'Furniture':
      return 'أثاث';
    case 'Machinery':
      return 'آلات';
    case 'Other':
      return 'أخرى';
    default:
      return category;
  }
}
