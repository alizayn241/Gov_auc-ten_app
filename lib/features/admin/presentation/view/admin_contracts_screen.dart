import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'contracts/contracts_models.dart';
import 'contracts/contracts_widgets.dart';
import 'shared/admin_shared.dart';

class AdminContractsScreen extends StatefulWidget {
  const AdminContractsScreen({super.key});

  @override
  State<AdminContractsScreen> createState() => _AdminContractsScreenState();
}

class _AdminContractsScreenState extends State<AdminContractsScreen> {
  bool loading = true;
  String? error;
  List<ContractRow> rows = const [];

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

      if (!mounted) return;
      setState(() {
        rows = (res as List)
            .map((row) => ContractRow.fromMap(Map<String, dynamic>.from(row)))
            .toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin • Contracts'),
        leading: const AppPageBackButton(fallbackRoute: '/admin'),
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AdminErrorCard(message: error!, onRetry: _load),
                  ),
                )
              : rows.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: AdminEmptyCard(
                          icon: Icons.description_outlined,
                          title: 'No contracts yet',
                          subtitle:
                              'Generated contracts will appear here once tender award flows are completed.',
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return ContractCard(contract: rows[index]);
                      },
                    ),
    );
  }
}
