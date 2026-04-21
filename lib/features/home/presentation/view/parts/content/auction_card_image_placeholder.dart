part of '../../home_screen.dart';

class _AuctionCardImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _HomeScreenTokens.navyMid,
      child: const Center(
        child: Icon(Icons.gavel_rounded, size: 36, color: Colors.white24),
      ),
    );
  }
}
