import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/sources/auctions_admin_remote_data_source.dart';
import 'auction_location_picker_screen.dart';
import '../viewmodel/auctions_view_model.dart';

class CreateAuctionScreen extends ConsumerStatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  ConsumerState<CreateAuctionScreen> createState() =>
      _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends ConsumerState<CreateAuctionScreen> {
  final _title = TextEditingController();
  final _startPrice = TextEditingController();
  final _location = TextEditingController();

  String? _category;

  DateTime? _startDate;
  DateTime? _endTime;
  double? _latitude;
  double? _longitude;

  Uint8List? _imageBytes;
  String? _imageName;

  bool _loading = false;
  String? _msg;

  final _remote = AuctionsAdminRemoteDataSource(Supabase.instance.client);

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
  void dispose() {
    _title.dispose();
    _startPrice.dispose();
    _location.dispose();
    super.dispose();
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);

      if (file == null) return;

      final bytes = await file.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    } catch (e) {
      setState(() {
        _msg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
      initialDate: now,
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (pickedTime == null) return;

    setState(() {
      _startDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickEndDate() async {
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
      _endTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _create() async {
    final title = _title.text.trim();
    final category = _category;
    final startPrice = num.tryParse(_startPrice.text.trim());
    final location = _location.text.trim();

    if (title.isEmpty ||
        category == null ||
        startPrice == null ||
        _startDate == null ||
        _endTime == null ||
        location.isEmpty ||
        _latitude == null ||
        _longitude == null) {
      setState(() => _msg = context.tr('Please fill all fields correctly', 'يرجى تعبئة جميع الحقول بشكل صحيح'));
      return;
    }

    if (!_endTime!.isAfter(_startDate!)) {
      setState(() => _msg = context.tr('End time must be after start date', 'يجب أن يكون وقت النهاية بعد وقت البداية'));
      return;
    }

    setState(() {
      _loading = true;
      _msg = null;
    });

    try {
      String? imageUrl;

      if (_imageBytes != null && _imageName != null) {
        imageUrl = await _remote.uploadAuctionImage(
          bytes: _imageBytes!,
          fileName: _imageName!,
        );
      }

      final id = await _remote.createAuction(
        title: title,
        category: category,
        startPrice: startPrice,
        startDate: _startDate!,
        endTime: _endTime!,
        location: location,
        latitude: _latitude,
        longitude: _longitude,
        imageUrl: imageUrl,
      );

      await ref.read(auctionsViewModelProvider.notifier).refresh();

      if (!mounted) return;
      context.go('/admin/auctions/$id/manage');
    } catch (e) {
      setState(() => _msg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _fmt(DateTime? d) =>
      d == null ? context.tr('Not selected', 'غير محدد') : d.toLocal().toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
        title: Text(context.tr('Create Auction', 'إنشاء مزاد')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
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
                    child: Text(c),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _category = value;
              });
            },
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _startPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.tr('Start Price', 'سعر البداية'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _location,
            readOnly: true,
            decoration: InputDecoration(
              labelText: context.tr('Auction Location', 'موقع المزاد'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: IconButton(
                onPressed: _loading ? null : _pickLocation,
                icon: const Icon(Icons.map_outlined),
              ),
            ),
            onTap: _loading ? null : _pickLocation,
          ),
          const SizedBox(height: 10),

          if (_latitude != null && _longitude != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EntryFlowTokens.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EntryFlowTokens.lightBorder),
              ),
              child: Text(
                '${context.tr('Coordinates', 'الإحداثيات')}: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              title: Text(context.tr('Start Date', 'تاريخ البداية')),
              subtitle: Text(_fmt(_startDate)),
              trailing: const Icon(Icons.date_range),
              onTap: _pickStartDate,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: ListTile(
              title: Text(context.tr('End Time', 'وقت النهاية')),
              subtitle: Text(_fmt(_endTime)),
              trailing: const Icon(Icons.schedule),
              onTap: _pickEndDate,
            ),
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _loading ? null : _pickImage,
            icon: const Icon(Icons.image_outlined),
              label: Text(
              _imageBytes == null
                  ? context.tr('Choose Auction Image', 'اختر صورة المزاد')
                  : context.tr('Image Selected', 'تم اختيار الصورة'),
            ),
          ),

          if (_imageBytes != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _imageBytes!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _create,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(context.tr('Create Auction', 'إنشاء مزاد')),
            ),
          ),

          if (_msg != null) ...[
            const SizedBox(height: 10),
            Text(
              _msg!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}
