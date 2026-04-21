import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import 'account_profile.dart';
import 'account_shared.dart';

class AccountViewFields extends StatelessWidget {
  final AccountProfile profile;

  const AccountViewFields({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AccountFieldTile(
          icon: Icons.person_rounded,
          iconColor: AccountTheme.blue,
          iconBg: const Color(0xFFE3F0FC),
          label: context.tr('Full name', 'الاسم الكامل'),
          value: AccountText.orDash(profile.displayName),
          editable: true,
        ),
        AccountFieldTile(
          icon: Icons.alternate_email_rounded,
          iconColor: const Color(0xFF475569),
          iconBg: const Color(0xFFF1F5F9),
          label: context.tr('Email address', 'البريد الإلكتروني'),
          value: AccountText.orDash(profile.email),
        ),
        AccountFieldTile(
          icon: Icons.phone_rounded,
          iconColor: AccountTheme.blue,
          iconBg: const Color(0xFFE3F0FC),
          label: context.tr('Phone number', 'رقم الهاتف'),
          value: AccountText.orDash(profile.phone),
          editable: true,
        ),
        AccountFieldTile(
          icon: Icons.credit_card_rounded,
          iconColor: AccountTheme.blue,
          iconBg: const Color(0xFFE3F0FC),
          label: context.tr('National ID', 'الرقم القومي'),
          value: AccountText.orDash(profile.nationalId),
          editable: true,
          isLast: true,
        ),
      ],
    );
  }
}

class AccountEditForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController displayNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController nationalIdCtrl;
  final String email;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const AccountEditForm({
    super.key,
    required this.formKey,
    required this.displayNameCtrl,
    required this.phoneCtrl,
    required this.nationalIdCtrl,
    required this.email,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AccountEditFieldTile(
            icon: Icons.person_rounded,
            iconColor: AccountTheme.blue,
            iconBg: const Color(0xFFE3F0FC),
            label: context.tr('Full name', 'الاسم الكامل'),
            controller: displayNameCtrl,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.tr(
                    'Please enter your full name.',
                    'يرجى إدخال الاسم الكامل.',
                  )
                : null,
          ),
          AccountFieldTile(
            icon: Icons.alternate_email_rounded,
            iconColor: const Color(0xFF475569),
            iconBg: const Color(0xFFF1F5F9),
            label: context.tr('Email address', 'البريد الإلكتروني'),
            value: AccountText.orDash(email),
          ),
          AccountEditFieldTile(
            icon: Icons.phone_rounded,
            iconColor: AccountTheme.blue,
            iconBg: const Color(0xFFE3F0FC),
            label: context.tr('Phone number', 'رقم الهاتف'),
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.tr(
                    'Please enter your phone number.',
                    'يرجى إدخال رقم الهاتف.',
                  )
                : null,
          ),
          AccountEditFieldTile(
            icon: Icons.credit_card_rounded,
            iconColor: AccountTheme.blue,
            iconBg: const Color(0xFFE3F0FC),
            label: context.tr('National ID', 'الرقم القومي'),
            controller: nationalIdCtrl,
            keyboardType: TextInputType.number,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.tr(
                    'Please enter your national ID.',
                    'يرجى إدخال الرقم القومي.',
                  )
                : null,
            isLast: true,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(context.tr('Cancel', 'إلغاء')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: isSaving ? null : onSave,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: AccountTheme.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(context.tr('Save changes', 'حفظ التغييرات')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AccountFieldTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final bool editable;
  final bool isLast;

  const AccountFieldTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.editable = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withOpacity(0.14), width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.45),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (editable)
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: cs.onSurface.withOpacity(0.25),
              ),
          ],
        ),
      ),
    );
  }
}

class AccountEditFieldTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool isLast;

  const AccountEditFieldTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AccountTheme.blue.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                validator: validator,
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.55),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
