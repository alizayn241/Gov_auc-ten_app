import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppPageBackButton extends StatelessWidget {
  final String? fallbackRoute;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const AppPageBackButton({
    super.key,
    this.fallbackRoute,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        if (fallbackRoute != null && fallbackRoute!.isNotEmpty) {
          context.go(fallbackRoute!);
        }
      },
      style: IconButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      ),
      icon: const Icon(Icons.arrow_back),
    );
  }
}
