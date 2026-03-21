import 'package:flutter/material.dart';

/// Rachae wordmark from bundled assets.
class RachaeLogo extends StatelessWidget {
  const RachaeLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
