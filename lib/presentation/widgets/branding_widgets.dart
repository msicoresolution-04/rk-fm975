import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';
import 'package:rkfm_broadcast/core/theme/app_theme.dart';

class RkfmLogo extends StatelessWidget {
  final double size;
  final bool showTagline;

  const RkfmLogo({super.key, this.size = 80, this.showTagline = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.16),
            child: SvgPicture.asset(
              'assets/logos/rkfm_logo.svg',
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 12),
          Text(
            AppConstants.appTagline,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class BrandedHeader extends StatelessWidget {
  final String? subtitle;

  const BrandedHeader({super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const RkfmLogo(size: 40),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('97.5 RKFM', style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }
}
