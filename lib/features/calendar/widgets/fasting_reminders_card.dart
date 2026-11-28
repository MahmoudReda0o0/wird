import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/features/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/features/settings/cubit/settings_cubit.dart';

/// «تذكير الصيام»: the two switches for «بكرة صيام» the night before
/// (white days, Arafah, Ashura; and Mondays and Thursdays).
class FastingRemindersCard extends StatelessWidget {
  const FastingRemindersCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final prefs = context.watch<SettingsCubit>().state;
    final allowed = context.watch<AdhanCubit>().state.appNotifications;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: c.cardShadow,
      ),
      child: Material(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            FastingSwitch(
              title: 'الأيام البيض وعرفة وعاشوراء',
              value: prefs.fastSpecial,
              onChanged: context.read<SettingsCubit>().setFastSpecial,
            ),
            Divider(
              height: 1,
              indent: AppSpace.s4,
              endIndent: AppSpace.s4,
              color: c.line,
            ),
            FastingSwitch(
              title: 'الإتنين والخميس',
              value: prefs.fastWeekly,
              onChanged: context.read<SettingsCubit>().setFastWeekly,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s4,
                0,
                AppSpace.s4,
                AppSpace.s3,
              ),
              child: Text(
                allowed
                    ? 'إشعار «بكرة صيام» الليلة اللي قبلها بعد العشاء بنص ساعة.'
                    : 'الإشعارات مقفولة من «إشعارات التطبيق» في الإعدادات.',
                style: AppText.caption.copyWith(
                  color: allowed ? c.inkMuted : c.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A «ذكّرني» switch row (also used in the day sheet).
class FastingSwitch extends StatelessWidget {
  const FastingSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle = 'ذكّرني الليلة اللي قبلها',
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: c.onPrimary,
      activeTrackColor: c.primary,
      secondary: Icon(
        value
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
        color: c.primary,
      ),
      title: Text(title, style: AppText.heading.copyWith(color: c.ink)),
      subtitle: Text(
        subtitle,
        style: AppText.body.copyWith(color: c.inkMuted),
      ),
    );
  }
}
