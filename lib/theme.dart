import 'package:flutter/material.dart';

class C {
  static const primary = Color(0xFF1E5A8A);
  static const primaryDark = Color(0xFF16456B);
  static const primaryLight = Color(0xFFE8F0F9);
  static const accent = Color(0xFFD97A2B);
  static const text = Color(0xFF1C2A3A);
  static const textLight = Color(0xFF5E6F82);
  static const border = Color(0xFFDBE3EC);
  static const success = Color(0xFF2E7D5E);
  static const successLight = Color(0xFFDDF3E8);
  static const error = Color(0xFFC0392B);
  static const errorLight = Color(0xFFFBE3E0);
  static const bg = Color(0xFFF3F6FB);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: C.primary,
    primary: C.primary,
    secondary: C.accent,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: C.primary,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
  );
}

BoxDecoration cardDecoration({Color color = Colors.white}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: C.border),
      boxShadow: const [
        BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
      ],
    );

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: cardDecoration(),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.primary),
      ),
    );
  }
}
