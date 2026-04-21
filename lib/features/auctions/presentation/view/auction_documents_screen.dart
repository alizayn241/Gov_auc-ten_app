import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/auction_document_item.dart';
import '../../data/sources/auctions_remote_data_source.dart';

class AuctionDocumentsScreen extends StatefulWidget {
  final String auctionId;

  const AuctionDocumentsScreen({super.key, required this.auctionId});

  @override
  State<AuctionDocumentsScreen> createState() =>
      _AuctionDocumentsScreenState();
}

class _AuctionDocumentsScreenState extends State<AuctionDocumentsScreen> {
  final _path = TextEditingController();
  final _docType = TextEditingController();
  final _remote = AuctionsAdminRemoteDataSource(Supabase.instance.client);

  String _visibility = 'public';
  bool loading = true;
  bool uploading = false;
  String? error;
  String? uploadedFileName;
  List<AuctionDocumentItem> docs = const [];

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

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\.\-]'), '_')
        .replaceAll(' ', '_');
  }

  String? _contentTypeForExtension(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return null;
    }
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

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.pickFiles(withData: true);
      if (result == null) return;

      final file = result.files.first;
      final fileBytes = file.bytes;

      if (fileBytes == null) {
        setState(() => error = 'File is empty');
        return;
      }

      setState(() {
        uploading = true;
        error = null;
      });

      final cleanName = _sanitizeFileName(file.name);
      final storagePath =
          'auctions/${widget.auctionId}/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
      final contentType = _contentTypeForExtension(file.extension);
      final storage = Supabase.instance.client.storage;

      await storage.from('auction-docs').uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      final publicUrl = storage.from('auction-docs').getPublicUrl(storagePath);
      final ext = file.extension?.toLowerCase();

      if (ext == 'pdf') {
        _docType.text = 'pdf';
      } else if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        _docType.text = 'image';
      } else {
        _docType.text = 'file';
      }

      setState(() {
        _path.text = publicUrl;
        uploadedFileName = file.name;
        uploading = false;
      });
    } on StorageException catch (e) {
      final lowerMessage = e.message.toLowerCase();
      setState(() {
        error = lowerMessage.contains('row-level security policy') ||
                e.statusCode == '403'
            ? context.tr(
                'Upload blocked by Supabase Storage policy. Run the auction documents storage SQL setup, then try again.',
                'تم منع الرفع بواسطة سياسة Supabase Storage. شغّل ملف SQL الخاص بمستندات المزاد ثم أعد المحاولة.',
              )
            : e.message;
        uploading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        uploading = false;
      });
    }
  }

  Future<void> _add() async {
    final path = _path.text.trim();
    final docType = _docType.text.trim();

    if (path.isEmpty || docType.isEmpty) {
      setState(() {
        error = context.tr(
          'Please upload a file first',
          'يرجى رفع ملف أولا',
        );
      });
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    try {
      await _remote.addDocument(
        auctionId: widget.auctionId,
        path: path,
        docType: docType,
        visibility: _visibility,
        createdBy: user?.id,
      );

      _path.clear();
      _docType.clear();
      uploadedFileName = null;

      await _load();
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      setState(() => error = 'Cannot open file');
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: uploading ? null : _pickAndUploadFile,
            icon: uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(
              uploading
                  ? context.tr('Uploading...', 'جاري الرفع...')
                  : context.tr('Upload Document', 'رفع مستند'),
            ),
          ),
          const SizedBox(height: 10),
          if (uploadedFileName != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(uploadedFileName!),
                subtitle: Text(_docType.text),
              ),
            ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _visibility,
            decoration: InputDecoration(
              labelText: context.tr('Visibility', 'إمكانية العرض'),
            ),
            items: [
              DropdownMenuItem(
                value: 'public',
                child: Text(context.tr('Public', 'عام')),
              ),
              DropdownMenuItem(
                value: 'participants',
                child: Text(context.tr('Participants', 'المشاركون')),
              ),
              DropdownMenuItem(
                value: 'winner',
                child: Text(context.tr('Winner', 'الفائز')),
              ),
              DropdownMenuItem(
                value: 'admin',
                child: Text(context.tr('Admin', 'الإدارة')),
              ),
            ],
            onChanged: (value) {
              setState(() => _visibility = value ?? 'public');
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.save),
            label: Text(context.tr('Save Document', 'حفظ المستند')),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 20),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (docs.isEmpty)
            Center(
              child: Text(context.tr('No documents yet', 'لا توجد مستندات')),
            )
          else
            ...docs.map((doc) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(doc.docType),
                  subtitle: Text(doc.visibility),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _openFile(doc.path),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
