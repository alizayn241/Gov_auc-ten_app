import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';
import 'package:gov_auction_app/core/widgets/app_page_back_button.dart';

import 'notifications/notifications_widgets.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  bool _push = true;
  bool _email = true;
  bool _sms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Notifications', 'الإشعارات')),
        leading: const AppPageBackButton(fallbackRoute: '/admin'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminNotificationsHint(
            title: context.tr('Notification Center', 'مركز الإشعارات'),
            subtitle: context.tr(
              'Configure channels, templates and delivery settings.',
              'اضبط القنوات والقوالب وإعدادات الإرسال.',
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _push,
                  onChanged: (value) => setState(() => _push = value),
                  title: Text(
                    context.tr('Push Notifications', 'إشعارات التطبيق'),
                  ),
                  subtitle: Text(
                    context.tr('Mobile app notifications', 'إشعارات تطبيق الهاتف'),
                  ),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  value: _email,
                  onChanged: (value) => setState(() => _email = value),
                  title: Text(
                    context.tr('Email Notifications', 'إشعارات البريد الإلكتروني'),
                  ),
                  subtitle: Text(
                    context.tr('Email delivery for users', 'إرسال البريد للمستخدمين'),
                  ),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  value: _sms,
                  onChanged: (value) => setState(() => _sms = value),
                  title: Text(
                    context.tr('SMS Notifications', 'إشعارات الرسائل النصية'),
                  ),
                  subtitle: Text(
                    context.tr(
                      'Phone SMS for critical alerts',
                      'رسائل هاتفية للتنبيهات المهمة',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: Text(context.tr('Templates', 'القوالب')),
              subtitle: Text(
                context.tr('Edit notification templates', 'تعديل قوالب الإشعارات'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr('Templates (demo)', 'القوالب (تجريبي)'),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('Saved (demo)', 'تم الحفظ (تجريبي)'))),
            ),
            icon: const Icon(Icons.save_outlined),
            label: Text(context.tr('Save', 'حفظ')),
          ),
        ],
      ),
    );
  }
}
