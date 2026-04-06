import 'dart:async';

class ChatMockApi {
  Future<String> reply(String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final m = userMessage.toLowerCase().trim();

    if (m.contains('auction') || m.contains('مزاد')) {
      return 'To participate in an auction: open the auction details, enter a bid higher than the current bid, then press Submit Bid.';
    }

    if (m.contains('watchlist') || m.contains('مفضلة')) {
      return 'Use the bookmark icon on any auction to add it to your Watchlist.';
    }

    if (m.contains('login') || m.contains('تسجيل')) {
      return 'If you have an account, go to Login and enter your email and password. If not, create one from Signup.';
    }

    return 'I can help with auctions, bidding rules, account access, watchlist, and app navigation. What do you need?';
  }
}
