import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/time/app_clock.dart';
import 'package:my_guide/core/widgets/custom_appbar.dart';
import 'package:my_guide/core/widgets/custom_screen.dart';
import 'package:my_guide/features/calendar/data/hijri_calendar.dart';
import 'package:my_guide/features/calendar/widgets/calendar_day_sheet.dart';
import 'package:my_guide/features/calendar/widgets/fasting_reminders_card.dart';
import 'package:my_guide/features/seasons/cubit/season_cubit.dart';

/// التقويم الهجري: a Hijri month (week from Saturday, Gregorian under each
/// day), the coming occasions, and the fasting reminders.
class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  /// Any day in the shown month.
  late DateTime _anchor = _today;

  static DateTime get _today {
    final now = AppClock.now();
    return DateTime(now.year, now.month, now.day);
  }

  static const _gregorianMonths = [
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

  static String gregorianLabel(DateTime d) =>
      '${d.day} ${_gregorianMonths[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final offset = context.watch<SeasonCubit>().state.hijriOffset;
    final today = _today;
    final days = HijriCalendarData.monthOf(_anchor, offset: offset);
    final upcoming = HijriCalendarData.upcoming(today, offset: offset);
    final showsToday = days.any((d) => d.date == today);
    return CustomScreen(
      appBar: CustomAppBar(
        title: 'التقويم الهجري',
        actions: [
          if (!showsToday)
            TextButton(
              onPressed: () => setState(() => _anchor = today),
              child: const Text('النهارده'),
            ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpace.s6),
        children: [
          _MonthCard(
            days: days,
            today: today,
            subtitle: _gregorianRange(days),
            onPrevious: () => setState(
              () => _anchor = HijriCalendarData.previousMonth(days),
            ),
            onNext: () =>
                setState(() => _anchor = HijriCalendarData.nextMonth(days)),
            onDay: (day) => showCalendarDaySheet(context, day, today),
          ),
          const SizedBox(height: AppSpace.s5),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpace.s1),
            child: Text(
              'المناسبات الجاية',
              style: AppText.heading.copyWith(color: context.wird.ink),
            ),
          ),
          const SizedBox(height: AppSpace.s2),
          _UpcomingList(
            items: upcoming,
            onTap: (u) => showCalendarDaySheet(context, u.day, today),
          ),
          const SizedBox(height: AppSpace.s5),
          const FastingRemindersCard(),
        ],
      ),
    );
  }

  String _gregorianRange(List<CalendarDay> days) {
    final a = days.first.date;
    final b = days.last.date;
    final first = _gregorianMonths[a.month - 1];
    final last = _gregorianMonths[b.month - 1];
    if (a.month == b.month) return '$first ${a.year}';
    if (a.year == b.year) return '$first – $last ${b.year}';
    return '$first ${a.year} – $last ${b.year}';
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.days,
    required this.today,
    required this.subtitle,
    required this.onPrevious,
    required this.onNext,
    required this.onDay,
  });

  final List<CalendarDay> days;
  final DateTime today;
  final String subtitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<CalendarDay> onDay;

  /// Saturday first, as on Egyptian calendars.
  static const _weekNames = [
    'سبت',
    'أحد',
    'إتنين',
    'تلات',
    'أربع',
    'خميس',
    'جمعة',
  ];

  /// Column of [d]: Saturday 0 … Friday 6.
  static int _column(DateTime d) => (d.weekday + 1) % 7;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final h = days.first.hijri;
    final title = '${h.monthName} ${h.year}';
    final cells = <CalendarDay?>[
      for (var i = 0; i < _column(days.first.date); i++) null,
      ...days,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: c.cardShadow,
      ),
      child: Material(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s3),
          child: Column(
            children: [
              Row(
                children: [
                  _NavButton(
                    tooltip: 'الشهر اللي فات',
                    // Mirrors in RTL: points right, the way back.
                    icon: Icons.chevron_left_rounded,
                    onTap: onPrevious,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppText.title.copyWith(color: c.ink),
                        ),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: AppText.caption.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  _NavButton(
                    tooltip: 'الشهر الجاي',
                    icon: Icons.chevron_right_rounded,
                    onTap: onNext,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s3),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: ExcludeSemantics(
                        child: Column(
                          children: [
                            Text(
                              _weekNames[i],
                              textAlign: TextAlign.center,
                              style: AppText.caption.copyWith(
                                color: c.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _Dot(
                              color: i == 2 || i == 5
                                  ? c.gold
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.s1),
              for (var r = 0; r < cells.length ~/ 7; r++)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.s1),
                  child: Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: cells[r * 7 + i] == null
                              ? const SizedBox(height: 50)
                              : _DayCell(
                                  day: cells[r * 7 + i]!,
                                  today: today,
                                  onTap: onDay,
                                ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpace.s3),
              const _Legend(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: c.surfaceSunken,
        foregroundColor: c.primary,
      ),
      icon: Icon(icon),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.onTap,
  });

  final CalendarDay day;
  final DateTime today;
  final ValueChanged<CalendarDay> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final isToday = day.date == today;
    final past = day.date.isBefore(today);
    final white = day.isWhiteDay;
    final named = day.named;
    final background = isToday
        ? c.primary
        : white
        ? c.goldSoft
        : Colors.transparent;
    final foreground = isToday
        ? c.onPrimary
        : white
        ? c.goldInk
        : c.ink;
    final dot = named != null
        ? (isToday ? c.onPrimary : c.primary)
        : day.isSunnahWeekday && !white
        ? c.gold
        : Colors.transparent;
    final g = day.date;
    return Semantics(
      button: true,
      label: [
        '${day.hijri.day} ${day.hijri.monthName}',
        _HijriCalendarScreenState.gregorianLabel(g),
        if (isToday) 'النهارده',
        if (white) 'من الأيام البيض',
        ?named?.name,
      ].join('، '),
      excludeSemantics: true,
      child: Opacity(
        opacity: past && !isToday ? 0.5 : 1,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: () => onTap(day),
            child: SizedBox(
              height: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.hijri.day}',
                    style: AppText.heading.copyWith(
                      color: foreground,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    '${g.day}',
                    style: AppText.caption.copyWith(
                      color: foreground.withValues(alpha: 0.75),
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _Dot(color: dot),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 4,
    height: 4,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final style = AppText.caption.copyWith(color: c.inkMuted);
    Widget item(Widget mark, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [mark, const SizedBox(width: 6), Text(text, style: style)],
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpace.s4,
      runSpacing: AppSpace.s1,
      children: [
        item(
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: c.goldSoft,
              border: Border.all(color: c.gold),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          'الأيام البيض',
        ),
        item(_Dot(color: c.gold), 'صيام مستحب'),
        item(_Dot(color: c.primary), 'مناسبة'),
      ],
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({required this.items, required this.onTap});

  final List<UpcomingOccasion> items;
  final ValueChanged<UpcomingOccasion> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
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
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: AppSpace.s4,
                  endIndent: AppSpace.s4,
                  color: c.line,
                ),
              _UpcomingRow(
                item: items[i],
                soonest: i == 0,
                onTap: () => onTap(items[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.item,
    required this.soonest,
    required this.onTap,
  });

  final UpcomingOccasion item;
  final bool soonest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final fast = item.occasion.fast;
    final h = item.day.hijri;
    final g = item.day.date;
    final white = identical(item.occasion, HijriCalendarData.whiteDays);
    final when = white
        ? 'من ${_HijriCalendarScreenState.gregorianLabel(g)} · 3 أيام صيام'
        : _HijriCalendarScreenState.gregorianLabel(g) + (fast ? ' · صيام' : '');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s4,
          vertical: AppSpace.s3,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s1),
              decoration: BoxDecoration(
                color: fast ? c.goldSoft : c.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  Text(
                    '${h.day}',
                    style: AppText.heading.copyWith(
                      color: fast ? c.goldInk : c.primary,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    h.monthName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      color: fast ? c.goldInk : c.primary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.occasion.name,
                    style: AppText.heading.copyWith(color: c.ink),
                  ),
                  Text(when, style: AppText.caption.copyWith(color: c.inkMuted)),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s2),
            Text(
              HijriCalendarData.daysLeftLabel(item.daysLeft),
              style: AppText.caption.copyWith(
                color: soonest ? c.primary : c.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
