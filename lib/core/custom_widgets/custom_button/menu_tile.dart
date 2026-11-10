import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_theme.dart';

/// Full-width tappable row that opens a section (Home and the azkar list).
class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final radius = BorderRadius.circular(AppRadius.md);

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: c.cardShadow),
      child: Material(
        color: c.surfaceRaised,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          highlightColor: c.surfaceSunken,
          splashColor: c.primarySoft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s4,
                vertical: AppSpace.s3,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, color: c.primary, size: 22),
                  ),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: AppText.heading.copyWith(color: c.ink)),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppText.body.copyWith(color: c.inkMuted),
                          ),
                      ],
                    ),
                  ),
                  // Mirrors in RTL, so it points left (forward).
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: c.inkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
