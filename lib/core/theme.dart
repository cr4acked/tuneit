import 'package:flutter/material.dart';

const _seed = Color(0xFF2E7D6B); // calm teal-green: "in tune" family

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
  );
}

/// Gauge colors: always paired with a text/icon cue for color-blind users.
Color centsColor(BuildContext context, double? cents, double inTuneCents) {
  final scheme = Theme.of(context).colorScheme;
  if (cents == null) return scheme.onSurfaceVariant;
  final abs = cents.abs();
  if (abs <= inTuneCents) return const Color(0xFF2E9E5B);
  if (abs <= 10) return const Color(0xFFC9A227);
  return scheme.onSurfaceVariant;
}
