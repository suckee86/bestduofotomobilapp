import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 120, this.padding = 8});

  final double width;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Best Duo Fotó',
      image: true,
      child: Container(
        width: width,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), blurRadius: 16),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 1.62,
          child: Image.asset(
            'assets/images/bestduo_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
