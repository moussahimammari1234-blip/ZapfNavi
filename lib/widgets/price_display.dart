import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PriceDisplay extends StatelessWidget {
  final double? price;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final bool showCurrency;

  const PriceDisplay({
    super.key,
    required this.price,
    this.fontSize = 26,
    this.color = Colors.black,
    this.fontWeight = FontWeight.w900,
    this.showCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    if (price == null) {
      return Text(
        '--',
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color.withValues(alpha: 0.3),
        ),
      );
    }

    final priceStr = price!.toStringAsFixed(3);
    final mainPart = priceStr.substring(0, priceStr.length - 1);
    final lastDigit = priceStr.substring(priceStr.length - 1);

    return RichText(
      text: TextSpan(
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
        children: [
          TextSpan(text: mainPart),
          WidgetSpan(
            child: Transform.translate(
              offset: Offset(0, -(fontSize * 0.28)),
              child: Text(
                lastDigit,
                style: GoogleFonts.outfit(
                  fontSize: fontSize * 0.52,
                  fontWeight: fontWeight,
                  color: color,
                ),
              ),
            ),
          ),
          if (showCurrency)
            TextSpan(
              text: ' €',
              style: GoogleFonts.outfit(
                fontSize: fontSize * 0.6,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }
}
