import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/app_notifications_service.dart';
import '../../data/sources/tenders_admin_remote_data_source.dart';

class CreateTenderScreen extends StatefulWidget {
  final String? tenderId;

  const CreateTenderScreen({super.key, this.tenderId});

  @override
  State<CreateTenderScreen> createState() => _CreateTenderScreenState();
}

class _CreateTenderScreenState extends State<CreateTenderScreen> {
  final _title = TextEditingController();
  final _referenceNo = TextEditingController();
  final _entity = TextEditingController();

  final _remote = TendersAdminRemoteDataSource(Supabase.instance.client);
  final _notifications = AppNotificationsService(Supabase.instance.client);

  DateTime? _submissionDeadline;
  DateTime? _openingDate;
  bool _loading = false;
  String? _message;
  String _status = 'open';

  static const List<String> _statuses = [
    'draft',
    'published',
    'open',
    'closed',
    'evaluating',
    'awarded',
    'cancelled',
  ];

  bool get _isEdit => widget.tenderId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadTender();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _referenceNo.dispose();
    _entity.dispose();
    super.dispose();
  }

  Future<void> _loadTender() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final tender = await _remote.getTenderById(widget.tenderId!);
      if (!mounted) return;

      _title.text = (tender['title'] ?? '').toString();
      _referenceNo.text = (tender['reference_no'] ?? '').toString();
      _entity.text = (tender['entity'] ?? '').toString();
      _status = (tender['status'] ?? 'draft').toString();
      _submissionDeadline = DateTime.tryParse(
        (tender['submission_deadline'] ?? '').toString(),
      )?.toLocal();
      _openingDate = DateTime.tryParse(
        (tender['opening_date'] ?? '').toString(),
      )?.toLocal();
    } catch (e) {
      _message = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      initialDate: now.add(const Duration(days: 7)),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (pickedTime == null) return;

    setState(() {
      _submissionDeadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickOpeningDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
      initialDate: _openingDate ?? now.add(const Duration(days: 8)),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _openingDate ?? now.add(const Duration(days: 8)),
      ),
    );
    if (pickedTime == null) return;

    setState(() {
      _openingDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveTender() async {
    final title = _title.text.trim();
    final referenceNo = _referenceNo.text.trim();
    final entity = _entity.text.trim();

    if (title.isEmpty || _submissionDeadline == null) {
      setState(() {
        _message = context.tr(
          'Please enter the tender title and submission deadline',
          'يرجى إدخال عنوان المناقصة وموعد الإغلاق',
        );
      });
      return;
    }

    if (!_submissionDeadline!.isAfter(DateTime.now())) {
      setState(() {
        _message = context.tr(
          'Submission deadline must be in the future',
          'يجب أن يكون موعد الإغلاق في المستقبل',
        );
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      if (_isEdit) {
        await _remote.updateTender(
          tenderId: widget.tenderId!,
          title: title,
          referenceNo: referenceNo,
          entity: entity,
          submissionDeadline: _submissionDeadline!,
          openingDate: _openingDate,
          status: _status,
        );
      } else {
        final tenderId = await _remote.createTender(
          title: title,
          referenceNo: referenceNo,
          entity: entity,
          submissionDeadline: _submissionDeadline!,
          openingDate: _openingDate,
          status: _status,
        );

        try {
          await _notifications.createTenderCreatedNotification(
            tenderId: tenderId,
            title: title,
            entity: entity,
            referenceNo: referenceNo,
          );
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? context.tr('Tender updated successfully', 'تم تحديث المناقصة بنجاح')
                : context.tr('Tender created successfully', 'تم إنشاء المناقصة بنجاح'),
          ),
        ),
      );
      context.go('/admin/tenders');
    } catch (e) {
      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return context.tr('Not selected', 'غير محدد');
    return value.toLocal().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? context.tr('Edit Tender', 'تعديل مناقصة')
              : context.tr('Create Tender', 'إنشاء مناقصة'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/tenders');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: InputDecoration(
              labelText: context.tr('Tender Title', 'عنوان المناقصة'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referenceNo,
            decoration: InputDecoration(
              labelText: context.tr('Reference Number', 'الرقم المرجعي'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _entity,
            decoration: InputDecoration(
              labelText: context.tr('Entity', 'الجهة'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: InputDecoration(
              labelText: context.tr('Status', 'الحالة'),
              border: OutlineInputBorder(),
            ),
            items: _statuses
                .map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  ),
                )
                .toList(),
            onChanged: _loading
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                  },
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: Text(context.tr('Submission Deadline', 'موعد الإغلاق')),
              subtitle: Text(_formatDate(_submissionDeadline)),
              trailing: const Icon(Icons.schedule),
              onTap: _loading ? null : _pickDeadline,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: Text(context.tr('Opening Date', 'تاريخ الفتح')),
              subtitle: Text(_formatDate(_openingDate)),
              trailing: const Icon(Icons.event_available),
              onTap: _loading ? null : _pickOpeningDate,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _saveTender,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(
                _isEdit
                    ? context.tr('Save Changes', 'حفظ التعديلات')
                    : context.tr('Create Tender', 'إنشاء مناقصة'),
              ),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}
