part of '../../home_screen.dart';

class _HomeAppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HomeAppBarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: Colors.white.withOpacity(0.85)),
      ),
    );
  }
}
