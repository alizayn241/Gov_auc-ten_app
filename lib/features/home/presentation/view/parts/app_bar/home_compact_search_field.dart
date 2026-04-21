part of '../../home_screen.dart';

class _HomeCompactSearchField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSubmitted;

  const _HomeCompactSearchField({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 13, color: Colors.white),
        decoration: InputDecoration(
          hintText: context.tr('Search…', 'بحث…'),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, size: 16, color: Colors.white.withOpacity(0.5)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero banner
// ─────────────────────────────────────────────────────────────────────────────
