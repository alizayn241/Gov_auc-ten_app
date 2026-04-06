import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_localizations.dart';
import '../../features/auth/presentation/viewmodel/auth_view_model.dart';

class HomeShell extends ConsumerWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  int _indexFromLocation(String location, {required bool isAdmin}) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/auctions')) return 0;

    if (isAdmin) {
      if (location.startsWith('/profile')) return 2;
      return 0;
    }

    if (location.startsWith('/watchlist')) return 1;
    if (location.startsWith('/my-bids')) return 2;
    if (location.startsWith('/profile')) return 3;

    return 0;
  }

  void _goToIndex(BuildContext context, int index, {required bool isAdmin}) {
    if (isAdmin) {
      switch (index) {
        case 0:
          context.go('/home');
          break;
        case 1:
          context.go('/admin');
          break;
        case 2:
          context.go('/profile');
          break;
      }
      return;
    }

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/watchlist');
        break;
      case 2:
        context.go('/my-bids');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  bool _shouldHideBottomNav(String location) {
    if (location.startsWith('/auction/')) return true;
    if (location.startsWith('/admin')) return true;
    if (location.startsWith('/staff')) return true;
    if (location.startsWith('/chat')) return true;

    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    final isAdmin = auth.isAdmin;
    final uri = GoRouterState.of(context).uri;
    final location = uri.toString();

    final currentIndex = _indexFromLocation(location, isAdmin: isAdmin);
    final hideBottomNav = _shouldHideBottomNav(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: hideBottomNav
          ? null
          : NavigationBar(
              height: 68,
              selectedIndex: currentIndex,
              onDestinationSelected: (i) =>
                  _goToIndex(context, i, isAdmin: isAdmin),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: isAdmin
                  ? [
                      NavigationDestination(
                        icon: Icon(Icons.gavel),
                        selectedIcon: Icon(Icons.gavel),
                        label: context.tr('Auctions', 'المزادات'),
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.admin_panel_settings_outlined),
                        selectedIcon: Icon(Icons.admin_panel_settings),
                        label: context.tr('Admin', 'الإدارة'),
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: context.tr('Profile', 'الملف الشخصي'),
                      ),
                    ]
                  : [
                      NavigationDestination(
                        icon: Icon(Icons.gavel),
                        selectedIcon: Icon(Icons.gavel),
                        label: context.tr('Auctions', 'المزادات'),
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.bookmark_border),
                        selectedIcon: Icon(Icons.bookmark),
                        label: context.tr('Watchlist', 'المتابعة'),
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.receipt_long),
                        selectedIcon: Icon(Icons.receipt_long),
                        label: context.tr('My Bids', 'مزايداتي'),
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: context.tr('Profile', 'الملف الشخصي'),
                      ),
                    ],
            ),
    );
  }
}
