import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';

/// The installed version beside the home title, e.g. «1.0.0». Opens
/// «عن التطبيق».
///
/// - A newer version is published: green «تحديث 1.1.0».
/// - Just updated: gold «جديد 1.1.0» until «عن التطبيق» is opened.
class VersionBadge extends StatelessWidget {
  const VersionBadge({super.key});

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
        : c.surfaceSunken;
    final foreground = update != null
        ? c.onPrimary
        : isNew
        ? c.onGold
        : c.inkMuted;
    final text = update != null
        ? 'تحديث ${update.version}'
        : isNew
        ? 'جديد ${state.version}'
        : state.version;

    return Semantics(
      button: true,
      label: update != null
          ? 'تحديث متاح ${update.version}، اضغط للتنزيل'
          : isNew
          ? 'إصدار جديد ${state.version}، اضغط لمعرفة الجديد'
          : 'الإصدار ${state.version}، عن التطبيق',
      excludeSemantics: true,
      child: Center(
        child: Material(
          color: background,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => Navigator.pushNamed(context, AppRoutes.appVersion),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (update != null || isNew) ...[
                      Icon(
                        update != null
                            ? Icons.system_update_rounded
                            : Icons.new_releases_rounded,
                        size: 16,
                        color: foreground,
                      ),
                      const SizedBox(width: 2),
                    ],
                    // Shrinks with … instead of overflowing the app bar's
                    // leading slot with large text or a long version.
                    Flexible(
                      child: Text(
                        text,
                        textDirection: update != null || isNew
                            ? null
                            : TextDirection.ltr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
