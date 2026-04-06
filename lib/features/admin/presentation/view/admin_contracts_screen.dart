import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminContractsScreen extends StatefulWidget {
  const AdminContractsScreen({super.key});

  @override
  State<AdminContractsScreen> createState() => _AdminContractsScreenState();
}

class _AdminContractsScreenState extends State<AdminContractsScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await Supabase.instance.client
          .from('contracts')
          .select('id,tender_id,vendor_id,contract_value,status,created_at')
          .order('created_at', ascending: false);

      setState(() {
        rows = (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  String _fmt(dynamic v) {
    if (v == null) return '-';
    final dt = DateTime.tryParse(v.toString());
    return dt?.toLocal().toString() ?? v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin • Contracts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : error != null
              ? Center(child: Text(error!))
              : rows.isEmpty
                  ? const Center(child: Text('No contracts yet'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final c = rows[i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Contract #${c["id"]}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    _Chip(text: (c['status'] ?? '').toString()),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Tender: ${c["tender_id"]}',
                                    style: TextStyle(color: cs.onSurfaceVariant)),
                                Text('Vendor: ${c["vendor_id"]}',
                                    style: TextStyle(color: cs.onSurfaceVariant)),
                                const SizedBox(height: 6),
                                Text(
                                  'Value: ${c["contract_value"]}',
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 6),
                                Text('Created: ${_fmt(c["created_at"])}',
                                    style: TextStyle(color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
