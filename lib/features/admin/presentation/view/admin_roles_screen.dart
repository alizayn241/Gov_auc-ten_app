import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';

import 'roles/roles_models.dart';
import 'roles/roles_widgets.dart';

class AdminRolesScreen extends StatelessWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = mockAdminRoles();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Roles', 'الأدوار')),
        leading: const AppPageBackButton(fallbackRoute: '/admin'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminRolesHintCard(
            title: context.tr('Role Management', 'إدارة الأدوار'),
            subtitle: context.tr(
              'Define permissions and access control for Citizen / Staff / Admin.',
              'حدد الصلاحيات والتحكم في الوصول للمواطن والموظف والمشرف.',
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((role) => AdminRoleCard(role: role)),
        ],
      ),
    );
  }
}
