import 'package:flutter/material.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/features/seasons/cubit/season_cubit.dart';

/// «باقي على رمضان · 3 أيام» on home, in the days before a seasonal theme.
class SeasonCountdownBanner extends StatelessWidget {
  const SeasonCountdownBanner({super.key, required this.state});

  final SeasonState state;

  /// 1 → يوم واحد, 2 → يومين, 3..10 → 3 أيام, more → 11 يوم.
  static String daysLabel(int days) {
    if (days <= 1) return 'يوم واحد';
    if (days == 2) return 'يومين';
    if (days <= 10) return '$days أيام';
    return '$days يوم';
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = state.upcoming;
    if (upcoming == null) return const SizedBox.shrink();
    final c = context.wird;
    final days = state.daysLeft;
    final label = upcoming.countdownLabel ?? '';
    final when = daysLabel(days);
    return Semantics(
      container: true,
      label: '$label: $when',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s4,
          vertical: AppSpace.s3,
        ),
        decoration: BoxDecoration(
          color: c.goldSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.goldInk, width: 2),
              ),
              child: Text(
                '${days < 1 ? 1 : days}',
                style: AppText.heading.copyWith(color: c.goldInk),
              ),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Text(
                '$label $when',
                style: AppText.heading.copyWith(color: c.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The seasonal pattern behind a screen, repeated and very faint.
class SeasonBackdrop extends StatelessWidget {
  const SeasonBackdrop({super.key, required this.state});

  final SeasonState state;

  @override
  Widget build(BuildContext context) {
    final active = state.active;
    final image = state.image(active?.patternImage);
    if (active == null || image == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Opacity(
        opacity: active.patternOpacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: image,
              repeat: ImageRepeat.repeat,
              // The tile is 240px: 80 logical pixels at 3x.
              scale: 3,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
      ),
    );
  }
}

/// The seasonal strip across the top of the home app bar.
class SeasonAppBarArt extends StatelessWidget {
  const SeasonAppBarArt({super.key, required this.state});

  final SeasonState state;

  @override
  Widget build(BuildContext context) {
    final image = state.image(state.active?.appbarImage);
    if (image == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Image(
            image: image,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

/// The note on the first day of a seasonal theme («رمضان كريم»).
Future<void> showSeasonNote(BuildContext context, SeasonState state) {
  final active = state.active!;
  final c = context.wird;
  final image = state.image(active.heroImage);
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: c.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s5,
          AppSpace.s5,
          AppSpace.s5,
          AppSpace.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null)
              Image(
                image: image,
                width: 150,
                height: 134,
                excludeFromSemantics: true,
              ),
            const SizedBox(height: AppSpace.s2),
            Text(
              active.noteTitle ?? '',
              textAlign: TextAlign.center,
              style: AppText.hero.copyWith(color: c.ink),
            ),
            if ((active.noteBody ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpace.s2),
              Text(
                active.noteBody!,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: c.inkMuted),
              ),
            ],
            const SizedBox(height: AppSpace.s5),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(active.noteButton),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
