import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'home_shell.dart';

import '../../features/auth/presentation/view/splash_screen.dart';
import '../../features/auth/presentation/view/login_screen.dart';
import '../../features/auth/presentation/view/signup_screen.dart';
import '../../features/onboarding/presentation/view/onboarding_screen.dart';

import '../../features/home/presentation/view/home_screen.dart';
import '../../features/profile/presentation/view/profile_screen.dart';
import '../../features/notifications/presentation/view/notifications_screen.dart';

import '../../features/auctions/presentation/view/auctions_list_screen.dart';
import '../../features/auctions/presentation/view/auction_details_screen.dart';
import '../../features/auctions/presentation/view/watchlist_screen.dart';
import '../../features/auctions/presentation/view/my_bids_screen.dart';
import '../../features/auctions/presentation/view/my_payments_screen.dart';

import '../../features/chat/presentation/view/chat_screen.dart';

import '../../features/admin/presentation/view/admin_dashboard_screen.dart';
import '../../features/admin/presentation/view/admin_reports_screen.dart';
import '../../features/admin/presentation/view/admin_tenders_screen.dart';
import '../../features/admin/presentation/view/admin_tender_participants_screen.dart';
import '../../features/staff/presentation/view/staff_approvals_screen.dart';
import '../../features/staff/presentation/view/staff_processes_screen.dart';

import 'package:gov_auction_app/features/admin/presentation/view/admin_users_screen.dart';
import 'package:gov_auction_app/features/admin/presentation/view/admin_roles_screen.dart';
import 'package:gov_auction_app/features/admin/presentation/view/admin_processes_screen.dart';
import 'package:gov_auction_app/features/admin/presentation/view/admin_notifications_screen.dart';
import 'package:gov_auction_app/features/admin/presentation/view/admin_audit_logs_screen.dart';
import 'package:gov_auction_app/features/admin/presentation/view/admin_settings_screen.dart';

import '../../features/auth/presentation/viewmodel/auth_state.dart';
import '../../features/auth/presentation/viewmodel/auth_view_model.dart';

// ✅ Tenders
import '../../features/tenders/presentation/view/tenders_list_screen.dart';
import '../../features/tenders/presentation/view/tender_details_screen.dart';
import '../../features/tenders/presentation/view/submit_proposal_screen.dart';
import '../../features/tenders/presentation/view/tender_ranking_screen.dart';
import '../../features/tenders/presentation/view/create_tender_screen.dart';

// ✅ Admin tender award
import '../../features/admin/presentation/view/admin_tender_award_screen.dart';
import '../../features/auctions/presentation/view/create_auction_screen.dart';
import '../../features/auctions/presentation/view/manage_auction_screen.dart';
import '../../features/auctions/presentation/view/auction_documents_screen.dart';
import '../../features/auctions/presentation/view/auction_participants_review_screen.dart';
import '../../features/auctions/presentation/view/finalize_auction_screen.dart';
import '../../features/auctions/presentation/view/confirm_payment_screen.dart';


String _roleOf(AuthState auth) => (auth.role ?? 'citizen').toLowerCase();

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authViewModelProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _GoRouterRefreshStream(authNotifier.stream),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),

      GoRoute(
        path: '/chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ChatScreen(),
      ),

      // ✅ Tenders
      GoRoute(
        path: '/tenders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const TendersListScreen(),
      ),
      GoRoute(
        path: '/tender/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            TenderDetailsScreen(tenderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tender/:id/submit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            SubmitProposalScreen(tenderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tender/:id/ranking',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            TenderRankingScreen(tenderId: state.pathParameters['id']!),
      ),

      // ✅ Admin
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/roles',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AdminRolesScreen(),
      ),
      GoRoute(
        path: '/admin/processes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AdminProcessesScreen(),
      ),
      GoRoute(
        path: '/admin/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: '/admin/audit-logs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AdminAuditLogsScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AdminSettingsScreen(),
      ),

      // ✅ Admin Tender Award
      GoRoute(
        path: '/admin/tenders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AdminTendersScreen(),
      ),
      GoRoute(
        path: '/admin/tenders/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CreateTenderScreen(),
      ),
      GoRoute(
        path: '/admin/tenders/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            CreateTenderScreen(tenderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/tenders/:id/participants',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AdminTenderParticipantsScreen(
          tenderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin/tenders/:id/award',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            AdminTenderAwardScreen(tenderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/tenders/:id/payment',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ConfirmPaymentScreen.tender(tenderId: state.pathParameters['id']!),
      ),
GoRoute(
  path: '/admin/auctions/create',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (_, __) => const CreateAuctionScreen(),
),
GoRoute(
  path: '/admin/auctions/:id/manage',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) =>
      ManageAuctionScreen(auctionId: state.pathParameters['id']!),
),
GoRoute(
  path: '/admin/auctions/:id/documents',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) =>
      AuctionDocumentsScreen(auctionId: state.pathParameters['id']!),
),
GoRoute(
  path: '/admin/auctions/:id/participants',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) =>
      AuctionParticipantsReviewScreen(auctionId: state.pathParameters['id']!),
),
GoRoute(
  path: '/admin/auctions/:id/finalize',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) =>
      FinalizeAuctionScreen(auctionId: state.pathParameters['id']!),
),
GoRoute(
  path: '/admin/auctions/:id/payment',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) =>
      ConfirmPaymentScreen(auctionId: state.pathParameters['id']!),
),
      // ✅ Staff
      GoRoute(
        path: '/staff/approvals',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const StaffApprovalsScreen(),
      ),
      GoRoute(
        path: '/staff/processes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const StaffProcessesScreen(),
      ),

      // ✅ Shell tabs
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/watchlist', builder: (_, __) => const WatchlistScreen()),
          GoRoute(path: '/my-bids', builder: (_, __) => const MyBidsScreen()),
          GoRoute(path: '/my-payments', builder: (_, __) => const MyPaymentsScreen()),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/auctions',
            builder: (context, state) => AuctionsListScreen(
              initialCategory: state.uri.queryParameters['category'] ?? 'All',
              initialSearch: state.uri.queryParameters['search'],
            ),
          ),
          GoRoute(
            path: '/auction/:id',
            builder: (context, state) =>
                AuctionDetailsScreen(auctionId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final auth = ref.read(authViewModelProvider);
      final loc = state.matchedLocation;

      if (!auth.isInitialized) {
        return loc == '/splash' ? null : '/splash';
      }

      if (!auth.hasSeenOnboarding) {
        final allowed = loc == '/splash' || loc == '/onboarding';
        if (loc == '/splash') return '/onboarding';
        if (!allowed) return '/onboarding';
        return null;
      }

      if (!auth.isAuthenticated) {
        final allowed = loc == '/login' || loc == '/signup' || loc == '/splash';
        if (!allowed) return '/login';
      }

      if (loc == '/splash') {
        return auth.isAuthenticated ? '/home' : '/login';
      }

      if (loc == '/onboarding') {
        return auth.isAuthenticated ? '/home' : '/login';
      }

      if (auth.isAuthenticated && (loc == '/login' || loc == '/signup')) {
        return '/home';
      }

      final role = _roleOf(auth);
      final wantsAdmin = loc.startsWith('/admin');
      final wantsStaff = loc.startsWith('/staff');
      final wantsWatchlist = loc.startsWith('/watchlist');
      final wantsMyBids = loc.startsWith('/my-bids');
      final wantsUserPayments = loc.startsWith('/my-payments');

      if (wantsAdmin && role != 'admin') return '/profile';

      // ✅ admin يستطيع دخول staff routes
      if (wantsStaff && !(role == 'staff' || role == 'admin')) return '/profile';
      if ((wantsWatchlist || wantsMyBids) && role == 'admin') return '/home';
      if (wantsUserPayments && role != 'citizen') return '/profile';

      return null;
    },
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
