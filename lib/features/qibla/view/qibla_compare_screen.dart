import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/widgets/custom_appbar.dart';
import 'package:my_guide/core/widgets/custom_screen.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:my_guide/features/prayer_times/data/prayer_city.dart';
import 'package:my_guide/features/qibla/data/compass_candidates.dart';
import 'package:my_guide/features/qibla/data/qibla_math.dart';
import 'package:my_guide/features/qibla/widgets/qibla_dial.dart';

/// Temporary: every compass package one under the other, to pick the most
/// accurate one on a real phone.
class QiblaCompareScreen extends StatelessWidget {
  const QiblaCompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final city = context.watch<CityCubit>().state;
    final qibla = QiblaMath.bearingToKaaba(city.latitude, city.longitude);
    return CustomScreen(
      appBar: const CustomAppBar(title: 'مقارنة البوصلات'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.s6),
        children: [
          Text(
            'حط الموبايل مفرود وثابت، وقارن كل بوصلة بالقبلة الحقيقية '
            '(جامع أو Google Maps). القبلة من ${city.name}: '
            '${qibla.toStringAsFixed(1)}°.',
            style: AppText.label.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: AppSpace.s3),
          for (final candidate in CompassCandidate.all) ...[
            _CandidateCard(candidate: candidate, city: city, qibla: qibla),
            const SizedBox(height: AppSpace.s3),
          ],
        ],
      ),
    );
  }
}

class _CandidateCard extends StatefulWidget {
  const _CandidateCard({
    required this.candidate,
    required this.city,
    required this.qibla,
  });
  final CompassCandidate candidate;
  final PrayerCity city;
  final double qibla;

  @override
  State<_CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<_CandidateCard> {
  late Stream<double> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _open();
  }

  @override
  void didUpdateWidget(_CandidateCard old) {
    super.didUpdateWidget(old);
    if (old.city.id != widget.city.id) _stream = _open();
  }

  Stream<double> _open() => widget.candidate.headings(
    widget.city.latitude,
    widget.city.longitude,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: c.cardShadow,
      ),
      child: StreamBuilder<double>(
        stream: _stream,
        builder: (context, snap) {
          final heading = snap.data;
          final delta = heading == null
              ? 0.0
              : QiblaMath.signedDelta(heading, widget.qibla);
          final aligned = heading != null && QiblaMath.isAligned(delta);
          final String status;
          if (snap.hasError) {
            status = 'مش شغالة على الموبايل ده: ${snap.error}';
          } else if (heading == null) {
            status = 'مستني قراية…';
          } else if (aligned) {
            status = 'في اتجاه القبلة';
          } else {
            status =
                'لفّ ${delta > 0 ? 'يمين' : 'شمال'} ${delta.abs().round()}°';
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.candidate.name,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                style: AppText.heading.copyWith(color: c.ink),
              ),
              Text(
                widget.candidate.note,
                style: AppText.caption.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: AppSpace.s3),
              Center(
                child: SizedBox(
                  width: 220,
                  child: QiblaDial(
                    heading: heading ?? 0,
                    qibla: widget.qibla,
                    aligned: aligned,
                    dimmed: heading == null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s2),
              Text(
                status,
                textAlign: TextAlign.center,
                style: AppText.title.copyWith(
                  color: aligned ? c.primary : c.ink,
                ),
              ),
              if (heading != null)
                Text(
                  'اتجاه الموبايل ${heading.toStringAsFixed(1)}°',
                  textAlign: TextAlign.center,
                  style: AppText.label.copyWith(color: c.inkMuted),
                ),
            ],
          );
        },
      ),
    );
  }
}
