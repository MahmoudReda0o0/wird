import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/features/about/cubit/app_version_cubit.dart';

/// The installed version beside the home title, e.g. «1.0.0». After an
/// update it turns gold with «جديد» until the user opens «عن التطبيق».
class VersionBadge extends StatelessWidget {
  const VersionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final state = context.watch<AppVersionCubit>().state;
    final isNew = state.isNew;

    final background = isNew ? c.gold : c.surfaceSunken;
    final foreground = isNew ? c.onGold : c.inkMuted;

    return Semantics(
      button: true,
      label: isNew
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
                    if (isNew) ...[
                      Icon(Icons.new_releases_rounded, size: 16, color: foreground),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      isNew ? 'جديد ${state.version}' : state.version,
                      textDirection: isNew ? null : TextDirection.ltr,
                      style: AppText.caption.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
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
