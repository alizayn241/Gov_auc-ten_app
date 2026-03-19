import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.onBack,
  });

  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const _AuthBackdrop(),
          if (showBackButton)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x24FFFFFF),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(.08)),
          ),
          child: Text(
            eyebrow,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: .3,
            ),
          ),
        ),
        SizedBox(height: compact ? 14 : 18),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 34 : 40,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(.88),
            fontSize: compact ? 14 : 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B1F3A),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: child,
      ),
    );
  }
}

class AuthInfoBanner extends StatelessWidget {
  const AuthInfoBanner({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0B3C8C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFieldSpacing extends StatelessWidget {
  const AuthFieldSpacing({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: child,
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A2E69),
            Color(0xFF154B9A),
            Color(0xFF0F264D),
          ],
        ),
      ),
      child: const Stack(
        children: [
          _AuthOrb(
            alignment: Alignment.topLeft,
            color: Color(0x33FDC32D),
            size: 220,
            dx: -50,
            dy: -20,
          ),
          _AuthOrb(
            alignment: Alignment.topRight,
            color: Color(0x26FFFFFF),
            size: 180,
            dx: 40,
            dy: 40,
          ),
          _AuthOrb(
            alignment: Alignment.bottomCenter,
            color: Color(0x2218C2A4),
            size: 260,
            dx: 0,
            dy: 100,
          ),
        ],
      ),
    );
  }
}

class _AuthOrb extends StatelessWidget {
  const _AuthOrb({
    required this.alignment,
    required this.color,
    required this.size,
    required this.dx,
    required this.dy,
  });

  final Alignment alignment;
  final Color color;
  final double size;
  final double dx;
  final double dy;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
