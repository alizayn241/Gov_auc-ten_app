import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AuctionLocationSelection {
  final String label;
  final double latitude;
  final double longitude;

  const AuctionLocationSelection({
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

class AuctionLocationPickerScreen extends StatefulWidget {
  final String? initialLabel;
  final double? initialLatitude;
  final double? initialLongitude;

  const AuctionLocationPickerScreen({
    super.key,
    this.initialLabel,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<AuctionLocationPickerScreen> createState() =>
      _AuctionLocationPickerScreenState();
}

class _AuctionLocationPickerScreenState
    extends State<AuctionLocationPickerScreen> {
  static const _defaultCenter = LatLng(30.0444, 31.2357);

  late final TextEditingController _labelController;
  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel ?? '');
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPoint = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _save() {
    final point = _selectedPoint;
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Tap the map to choose a location first.',
              'اضغط على الخريطة لاختيار الموقع أولاً.',
            ),
          ),
        ),
      );
      return;
    }

    final label = _labelController.text.trim().isEmpty
        ? 'Lat ${point.latitude.toStringAsFixed(5)}, Lng ${point.longitude.toStringAsFixed(5)}'
        : _labelController.text.trim();

    Navigator.of(context).pop(
      AuctionLocationSelection(
        label: label,
        latitude: point.latitude,
        longitude: point.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = _selectedPoint ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Pick Auction Location', 'اختيار موقع المزاد')),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(context.tr('Save', 'حفظ')),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: initialTarget,
                initialZoom: _selectedPoint == null ? 10 : 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (_, point) => setState(() => _selectedPoint = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.gov_auction_app',
                ),
                if (_selectedPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPoint!,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: context.tr('Location label', 'اسم الموقع'),
                    hintText: context.tr(
                      'Example: Nasr City, Cairo',
                      'مثال: مدينة نصر، القاهرة',
                    ),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: EntryFlowTokens.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: EntryFlowTokens.lightBorder),
                  ),
                  child: Text(
                    _selectedPoint == null
                        ? context.tr(
                            'Tap on the map to select the auction location.',
                            'اضغط على الخريطة لتحديد موقع المزاد.',
                          )
                        : context.tr(
                            'Selected: ${_selectedPoint!.latitude.toStringAsFixed(5)}, ${_selectedPoint!.longitude.toStringAsFixed(5)}',
                            'تم التحديد: ${_selectedPoint!.latitude.toStringAsFixed(5)}, ${_selectedPoint!.longitude.toStringAsFixed(5)}',
                          ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(context.tr('Use This Location', 'استخدام هذا الموقع')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
