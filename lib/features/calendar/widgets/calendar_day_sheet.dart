import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/features/calendar/data/hijri_calendar.dart';
import 'package:my_guide/features/calendar/widgets/fasting_reminders_card.dart';
import 'package:my_guide/features/settings/cubit/settings_cubit.dart';

/// A day's details: both dates, what's on it, and its fasting reminder.
Future<void> showCalendarDaySheet(
  BuildContext context,
  CalendarDay day,
  DateTime today,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.wird.surfaceRaised,
    builder: (_) => _DaySheet(day: day, today: today),
  );
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.day, required this.today});

  final CalendarDay day;
  final DateTime today;

  static const _weekdays = {
    DateTime.saturday: 'السبت',
    DateTime.sunday: 'الأحد',
    DateTime.monday: 'الإتنين',
    DateTime.tuesday: 'التلات',
    DateTime.wednesday: 'الأربع',
    DateTime.thursday: 'الخميس',
    DateTime.friday: 'الجمعة',
  };

  static const _months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final prefs = context.watch<SettingsCubit>().state;
    final g = day.date;
    final h = day.hijri;
    final diff = DateTime.utc(g.year, g.month, g.day)
        .difference(DateTime.utc(today.year, today.month, today.day))
        .inDays;
    final when = diff < 0 ? 'فات' : HijriCalendarData.daysLeftLabel(diff);
    final shown = [
      ?day.named,
      if (day.isWhiteDay) HijriCalendarData.whiteDays,
      if (day.isSunnahWeekday) HijriCalendarData.weekday,
    ];
    final white = day.isWhiteDay;
    final special = (day.named?.fast ?? false) || white;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s5,
          0,
          AppSpace.s5,
          AppSpace.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: special ? c.goldSoft : c.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${h.day}',
                        style: AppText.hero.copyWith(
                          color: special ? c.goldInk : c.primary,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        h.monthName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(
                          color: special ? c.goldInk : c.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.label, style: AppText.title.copyWith(color: c.ink)),
                      Text(
                        '${_weekdays[g.weekday]} ${g.day} ${_months[g.month - 1]} ${g.year} · $when',
                        style: AppText.body.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            for (final o in shown) ...[
              const SizedBox(height: AppSpace.s3),
              Container(
                padding: const EdgeInsets.all(AppSpace.s3),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      o.fast ? Icons.wb_sunny_outlined : Icons.event_outlined,
                      color: o.fast ? c.goldInk : c.primary,
                    ),
                    const SizedBox(width: AppSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.name,
                            style: AppText.heading.copyWith(color: c.ink),
                          ),
                          if (o.note != null)
                            Text(
                              o.note!,
                              style: AppText.body.copyWith(color: c.inkMuted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (shown.isEmpty) ...[
              const SizedBox(height: AppSpace.s3),
              Text(
                'مفيش مناسبة في اليوم ده.',
                style: AppText.body.copyWith(color: c.inkMuted),
              ),
            ],
            if (diff > 0 && (special || day.isSunnahWeekday)) ...[
              const SizedBox(height: AppSpace.s2),
              special
                  ? FastingSwitch(
                      title: 'ذكّرني بالصيام',
                      subtitle:
                          'الليلة اللي قبلها بعد العشاء (الأيام البيض وعرفة وعاشوراء)',
                      value: prefs.fastSpecial,
                      onChanged: context.read<SettingsCubit>().setFastSpecial,
                    )
                  : FastingSwitch(
                      title: 'ذكّرني بالصيام',
                      subtitle:
                          'الليلة اللي قبلها بعد العشاء (كل إتنين وخميس)',
                      value: prefs.fastWeekly,
                      onChanged: context.read<SettingsCubit>().setFastWeekly,
                    ),
            ],
            const SizedBox(height: AppSpace.s3),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text('تمام'),
            ),
          ],
        ),
      ),
    );
  }
}
