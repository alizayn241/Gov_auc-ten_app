part of '../../home_screen.dart';

class _HomeScreenTokens {
  static const Color navy = Color(0xFF091F45);
  static const Color navyMid = Color(0xFF0D3478);
  static const Color blue = Color(0xFF1565C0);
  static const Color gold = Color(0xFFFDC32D);
  static const Color goldDark = Color(0xFFB45309);
  static const Color liveGreen = Color(0xFF16A34A);
  static const Color liveGreenBg = Color(0xFF4ADE80);

  static const Gradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navyMid, Color(0xFF1A5199)],
    stops: [0.0, 0.55, 1.0],
  );

  static const Gradient tenderBannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyMid, blue],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Home screen
// ─────────────────────────────────────────────────────────────────────────────
