import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/localization/app_localizations.dart';

import 'account_shared.dart';

class AccountAppBar extends SliverPersistentHeaderDelegate {
  final bool isEditing;
  final bool isSaving;
  final bool hasProfile;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const AccountAppBar({
    required this.isEditing,
    required this.isSaving,
    required this.hasProfile,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  @override
  double get minExtent => kToolbarHeight + 12;

  @override
  double get maxExtent => kToolbarHeight + 12;

  @override
  bool shouldRebuild(covariant AccountAppBar oldDelegate) {
    return isEditing != oldDelegate.isEditing ||
        isSaving != oldDelegate.isSaving;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AccountTheme.navy,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: kToolbarHeight + 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              _BarIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
              Text(
                context.tr('Account', 'الحساب'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              if (hasProfile) ...[
                if (isEditing) ...[
                  _BarIconButton(
                    icon: Icons.close_rounded,
                    onTap: isSaving ? null : onCancel,
                  ),
                  const SizedBox(width: 6),
                  _BarActionButton(
                    label: context.tr('Save', 'حفظ'),
                    loading: isSaving,
                    onTap: isSaving ? null : onSave,
                  ),
                ] else
                  _BarActionButton(
                    label: context.tr('Edit', 'تعديل'),
                    onTap: onEdit,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _BarIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white.withOpacity(onTap == null ? 0.35 : 0.9),
        ),
      ),
    );
  }
}

class _BarActionButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _BarActionButton({
    required this.label,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AccountTheme.gold.withOpacity(onTap == null ? 0.4 : 1.0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AccountTheme.navy),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AccountTheme.navy,
                  ),
                ),
        ),
      ),
    );
  }
}
