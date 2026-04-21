import 'package:flutter/material.dart';
import 'package:gov_auction_app/core/theme/entry_flow_tokens.dart';

class AuthFormTheme {
  static const inputTextStyle = TextStyle(color: Colors.white);

  static InputDecorationTheme inputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: EntryFlowTokens.inputFill,
      labelStyle: const TextStyle(
        color: EntryFlowTokens.textMuted,
      ),
      prefixIconColor: EntryFlowTokens.textMuted,
      suffixIconColor: EntryFlowTokens.textMuted,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EntryFlowTokens.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: EntryFlowTokens.accent,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC25A5A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC25A5A)),
      ),
    );
  }
}
