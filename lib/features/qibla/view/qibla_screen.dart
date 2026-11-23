import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/time/app_clock.dart';
import 'package:my_guide/core/widgets/custom_appbar.dart';
import 'package:my_guide/core/widgets/custom_screen.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/prayer_times/data/prayer_timing_data.dart';
import 'package:my_guide/features/prayer_times/widgets/prayer_city_picker.dart';
import 'package:my_guide/features/qibla/cubit/qibla_cubit.dart';
import 'package:my_guide/features/qibla/cubit/qibla_state.dart';
import 'package:my_guide/features/qibla/data/device_heading_source.dart';
import 'package:my_guide/features/qibla/data/heading_source.dart';
import 'package:my_guide/features/qibla/data/qibla_math.dart';
import 'package:my_guide/features/qibla/widgets/accuracy_bars.dart';
import 'package:my_guide/features/qibla/widgets/qibla_dial.dart';
import 'package:my_guide/features/qibla/widgets/qibla_notice.dart';
import 'package:my_guide/features/qibla/widgets/sun_card.dart';
import 'package:my_guide/features/qibla/widgets/sun_help_sheet.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:wakelock_plus/wakelock_plus.dart';

/// The qibla from the chosen city: a dial that turns with the phone, the
/// sun as a second way, and a plain warning when the compass can't be
/// trusted. The screen stays on while it's open.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key, this.source, this.nowUtc});

  /// The phone's compass; tests pass a fake.
  final HeadingSource? source;

  /// The clock for the sun; tests pass a fixed time.
  final DateTime Function()? nowUtc;

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  late final QiblaCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = QiblaCubit(
      widget.source ?? DeviceHeadingSource(),
      context.read<CityCubit>().state,
      nowUtc: widget.nowUtc,
    );
    unawaited(_cubit.start());
    unawaited(_keepScreenOn(true));
  }

  @override
  void dispose() {
    unawaited(_keepScreenOn(false));
    unawaited(_cubit.close());
    super.dispose();
  }

  static Future<void> _keepScreenOn(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (e) {
      debugPrint('Wakelock unavailable: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<CityCubit, PrayerCity>(
        listener: (_, city) => _cubit.setCity(city),
        child: CustomScreen(
          appBar: CustomAppBar(
            title: 'القبلة',
            actions: [
              // Temporary: compare the compass packages on a real phone.
              IconButton(
                tooltip: 'مقارنة البوصلات',
                icon: Icon(Icons.compare_arrows_rounded, color: c.primary),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.qiblaCompare),
              ),
              Tooltip(
                message: 'الشاشة هتفضل منوّرة طول ما إنت هنا',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: c.inkMuted,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          body: BlocConsumer<QiblaCubit, QiblaState>(
            listenWhen: (a, b) => b.alignedCount > a.alignedCount,
            listener: (_, _) => HapticFeedback.lightImpact(),
            builder: (context, s) => _Body(state: s),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});
  final QiblaState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final c = context.wird;
    final live = s.status == QiblaStatus.live;
    final sunAz = s.sun.isUp ? s.sun.azimuth : null;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wraps under the chip on a narrow phone with large text.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpace.s3,
            runSpacing: AppSpace.s2,
            children: [
              PrayerCityChip(name: s.city.name),
              if (live) AccuracyBars(level: s.accuracy),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          if (s.status == QiblaStatus.loading)
            const SizedBox(
              height: 316,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (live) ...[
            Center(
              child: QiblaDial(
                heading: s.heading ?? s.qibla,
                qibla: s.qibla,
                aligned: s.aligned,
                dimmed: s.unreliable,
                sunAzimuth: sunAz,
              ),
            ),
            const SizedBox(height: AppSpace.s2),
            _Status(state: s),
          ],
          if (s.status == QiblaStatus.noSensor) _NoCompass(state: s),
          if (live && s.unreliable) ...[
            const SizedBox(height: AppSpace.s3),
            _warning(s),
          ],
          if (s.kaabaSunToday != null) ...[
            const SizedBox(height: AppSpace.s3),
            QiblaNotice(
              icon: Icons.wb_sunny_outlined,
              gold: true,
              title:
                  'النهارده ${PrayerTimingData.format(tz.TZDateTime.from(s.kaabaSunToday!, AppClock.cairo))} الشمس فوق الكعبة',
              body: 'في اللحظة دي، ضل أي حاجة واقفة بيشاور عكس القبلة بالظبط.',
            ),
          ],
          const SizedBox(height: AppSpace.s3),
          SunCard(
            hasCompass: s.status != QiblaStatus.noSensor,
            sunUp: s.sun.isUp,
            sunDelta: s.sunDelta,
            onTap: () => showSunHelp(context, s.sunDelta, sunUp: s.sun.isUp),
          ),
          const SizedBox(height: AppSpace.s3),
          _NextPrayer(city: s.city, color: c.inkMuted),
        ],
      ),
    );
  }
}

/// Calibration first, then iron nearby, then frozen readings.
Widget _warning(QiblaState s) {
  if (s.needsCalibration || s.accuracy == CompassAccuracyLevel.unreliable) {
    return const QiblaNotice.calibrate();
  }
  if (s.interference) return const QiblaNotice.interference();
  return const QiblaNotice.flat();
}

/// «لفّ يمين 40°», «إنت في اتجاه القبلة», or «الاتجاه مش دقيق دلوقتي».
class _Status extends StatelessWidget {
  const _Status({required this.state});
  final QiblaState state;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final s = state;
    final String title;
    final String sub;
    IconData? icon;
    var color = c.ink;
    if (s.unreliable) {
      title = 'الاتجاه مش دقيق دلوقتي';
      sub = s.needsCalibration || s.accuracy == CompassAccuracyLevel.unreliable
          ? 'عاير البوصلة الأول'
          : s.interference
          ? 'البوصلة متأثرة بحاجة جنبك'
          : 'الموبايل لازم يبقى مفرود';
    } else if (s.aligned) {
      title = 'إنت في اتجاه القبلة';
      sub = 'ثبّت الموبايل كده';
      icon = Icons.check_rounded;
      color = c.primary;
    } else {
      final right = s.delta > 0;
      title = 'لفّ ${right ? 'يمين' : 'شمال'} ${s.delta.abs().round()}°';
      sub = 'لحد ما الكعبة تيجي عند السهم فوق';
      icon = right ? Icons.rotate_right_rounded : Icons.rotate_left_rounded;
    }
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 24),
                const SizedBox(width: AppSpace.s1),
              ],
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.title.copyWith(
                    fontSize: 22,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// No compass: a still, north-up map with the angle, and the sun below.
class _NoCompass extends StatelessWidget {
  const _NoCompass({required this.state});
  final QiblaState state;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final s = state;
    return Column(
      children: [
        QiblaDial(
          heading: 0,
          qibla: s.qibla,
          aligned: false,
          dimmed: false,
          sunAzimuth: s.sun.isUp ? s.sun.azimuth : null,
          showPointer: false,
        ),
        Text(
          'الموبايل ده مفيهوش بوصلة',
          textAlign: TextAlign.center,
          style: AppText.title.copyWith(color: c.ink),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.s2,
          children: [
            Text(
              '${s.qibla.round()}°',
              textDirection: TextDirection.ltr,
              style: AppText.display.copyWith(color: c.primary),
            ),
            Text(
              QiblaMath.compassPoint(s.qibla),
              style: AppText.heading.copyWith(color: c.primary),
            ),
          ],
        ),
        Text(
          'من الشمال مع عقارب الساعة. أسهل طريقة: استخدم الشمس تحت.',
          textAlign: TextAlign.center,
          style: AppText.label.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }
}

/// «العصر بعد 38 دقيقة · 2:38 م»
class _NextPrayer extends StatelessWidget {
  const _NextPrayer({required this.city, required this.color});
  final PrayerCity city;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final now = PrayerTimingData.now();
    final next = PrayerTimingData.next(city, now);
    final name = next.entry.name + (next.isTomorrow ? ' (غدًا)' : '');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.schedule_rounded, size: 18, color: c.primary),
        const SizedBox(width: AppSpace.s2),
        Flexible(
          child: Text(
            '$name بعد ${PrayerTimingData.remaining(next.entry.time.difference(now))}'
            ' · ${PrayerTimingData.format(next.entry.time)}',
            textAlign: TextAlign.center,
            style: AppText.label.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
