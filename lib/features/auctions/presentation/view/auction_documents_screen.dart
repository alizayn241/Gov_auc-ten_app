import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import '../../data/models/auction_document_item.dart';
import '../../data/sources/auctions_remote_data_source.dart';

class AuctionDocumentsScreen extends StatefulWidget {
  final String auctionId;
  const AuctionDocumentsScreen({super.key, required this.auctionId});

  @override
  State<AuctionDocumentsScreen> createState() => _AuctionDocumentsScreenState();
}

class _AuctionDocumentsScreenState extends State<AuctionDocumentsScreen> {
  final _path = TextEditingController();
  final _docType = TextEditingController(text: 'terms');
  String _visibility = 'public';

  bool loading = true;
  String? error;
  List<AuctionDocumentItem> docs = const [];

  final _remote = AuctionsAdminRemoteDataSource(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _path.dispose();
    _docType.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await _remote.getDocuments(widget.auctionId);
      setState(() {
        docs = res;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _add() async {
    final path = _path.text.trim();
    final docType = _docType.text.trim();

    if (path.isEmpty || docType.isEmpty) {
      setState(() => error = context.tr('Please enter path and doc type', 'يرجى إدخال المسار ونوع المستند'));
      return;
    }

    try {
      await _remote.addDocument(
        auctionId: widget.auctionId,
        path: path,
        docType: docType,
        visibility: _visibility,
      );
      _path.clear();
      await _load();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppPageBackButton(fallbackRoute: '/admin'),
        title: Text(context.tr('Auction Documents', 'مستندات المزاد')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _path,
            decoration: InputDecoration(labelText: context.tr('Document path', 'مسار المستند')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _docType,
            decoration: InputDecoration(labelText: context.tr('Doc type', 'نوع المستند')),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _visibility,
            decoration: InputDecoration(labelText: context.tr('Visibility', 'إمكانية العرض')),
            items: [
              DropdownMenuItem(value: 'public', child: Text(context.tr('public', 'عام'))),
              DropdownMenuItem(value: 'participants', child: Text(context.tr('participants', 'المشاركون'))),
              DropdownMenuItem(value: 'winner', child: Text(context.tr('winner', 'الفائز'))),
              DropdownMenuItem(value: 'admin', child: Text(context.tr('admin', 'الإدارة'))),
            ],
            onChanged: (v) => setState(() => _visibility = v ?? 'public'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.upload_file),
            label: Text(context.tr('Add Document', 'إضافة مستند')),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          if (loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (docs.isEmpty)
            Center(child: Text(context.tr('No documents yet', 'لا توجد مستندات بعد')))
          else
            ...docs.map((d) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    title: Text(d.docType),
                    subtitle: Text('${d.path}\nVisibility: ${d.visibility}'),
                    isThreeLine: true,
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
