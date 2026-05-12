import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool centerContent;
  final bool centerBrand;
  final double titleSubtitleSpacing;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.centerContent = false,
    this.centerBrand = false,
    this.titleSubtitleSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final textAlign = centerContent ? TextAlign.center : TextAlign.right;
    final brand = Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(38),
          child: Image.asset(
            'assets/images/lingova_logo.png',
            width: 260,
            height: 260,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: centerContent
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.end,
      children: [
        if (centerBrand) Center(child: brand) else brand,
        SizedBox(height: 10),
        Align(
          alignment: centerContent ? Alignment.center : Alignment.centerRight,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              title,
              textAlign: textAlign,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        SizedBox(height: titleSubtitleSpacing),
        Align(
          alignment: centerContent ? Alignment.center : Alignment.centerRight,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              subtitle,
              textAlign: textAlign,
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
