import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';

/// The installed version as a card (at the end of Settings), with the same
/// cycle as `VersionBadge`. Opens «عن التطبيق» (details and the QR).
///
/// - A newer version is published: green «تحديث متاح 1.1.0».
/// - Just updated: gold «جديد 1.1.0» until «عن التطبيق» is opened.
/// - Otherwise: plain «الإصدار 1.0.0».
class VersionCard extends StatelessWidget {
  const VersionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final state = context.watch<AppVersionCubit>().state;
    final update = state.update;
    final isNew = update == null && state.isNew;

    final background = update != null
        ? c.primary
        : isNew
        ? c.gold
        : c.surfaceRaised;
    final foreground = update != null
        ? c.onPrimary
        : isNew
        ? c.onGold
        : c.ink;
    final muted = update != null || isNew
        ? foreground.withValues(alpha: 0.85)
        : c.inkMuted;
    final icon = update != null
        ? Icons.system_update_rounded
        : isNew
        ? Icons.new_releases_rounded
        : Icons.verified_outlined;
    final title = update != null
        ? 'تحديث متاح ${update.version}'
        : isNew
        ? 'جديد ${state.version}'
        : 'الإصدار ${state.version}';
    final subtitle = update != null
        ? 'اضغط عشان تنزّل النسخة الجديدة'
        : isNew
        ? 'اعرف الجديد في النسخة دي'
        : 'تفاصيل النسخة وQR التحميل';

    return Semantics(
      button: true,
      label: '$title، $subtitle',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: c.cardShadow,
        ),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.appVersion),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Row(
                children: [
                  Icon(icon, color: foreground, size: 28),
                  const SizedBox(width: AppSpace.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppText.heading.copyWith(color: foreground),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppText.body.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.s2),
                  Icon(Icons.qr_code_2_rounded, color: foreground, size: 28),
                  const SizedBox(width: AppSpace.s1),
                  // Mirrors in RTL, so it points left (forward).
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: muted,
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
