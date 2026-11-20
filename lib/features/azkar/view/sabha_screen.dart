import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/feature/model/azkar_model.dart';
import 'package:my_guide/feature/screen/azkar/cubit/azkar_progress_cubit.dart';
import 'package:my_guide/feature/screen/azkar/cubit/sabha_cubit.dart';

/// The calm palette used only on the sabha screen: low contrast around a
/// single clear accent, so the zikr and the count button stand out.
@immutable
class SabhaColors {
  const SabhaColors({
    required this.bg,
    required this.raised,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.muted,
    required this.zikr,
    required this.accent,
    required this.onAccent,
    required this.track,
    required this.gold,
    required this.goldSoft,
    required this.goldInk,
    required this.buttonShadow,
  });

  final Color bg;
  final Color raised;
  final Color line;
  final Color lineStrong;
  final Color ink;
  final Color muted;
  final Color zikr;
  final Color accent;
  final Color onAccent;
  final Color track;
  final Color gold;
  final Color goldSoft;
  final Color goldInk;
  final List<BoxShadow> buttonShadow;

  static const light = SabhaColors(
    bg: Color(0xFFECEEE8),
    raised: Color(0xFFF7F7F3),
    line: Color(0xFFD9DDD4),
    lineStrong: Color(0xFF8A948F),
    ink: Color(0xFF22302B),
    muted: Color(0xFF5C6964),
    zikr: Color(0xFF1F2B27),
    accent: Color(0xFF3D7A6D),
    onAccent: Color(0xFFFFFFFF),
    track: Color(0xFFDCE2DA),
    gold: Color(0xFFD8A23A),
    goldSoft: Color(0xFFF4EAD2),
    goldInk: Color(0xFF7A5300),
    buttonShadow: [
      BoxShadow(color: Color(0x2922302B), blurRadius: 18, offset: Offset(0, 6)),
    ],
  );

  static const dark = SabhaColors(
    bg: Color(0xFF111917),
    raised: Color(0xFF18221F),
    line: Color(0xFF26322E),
    lineStrong: Color(0xFF6C7A75),
    ink: Color(0xFFE6ECE8),
    muted: Color(0xFF95A49E),
    zikr: Color(0xFFF1E8D4),
    accent: Color(0xFF7FBFAE),
    onAccent: Color(0xFF0F1714),
    track: Color(0xFF22302B),
    gold: Color(0xFFE1B452),
    goldSoft: Color(0xFF2E2611),
    goldInk: Color(0xFFECC266),
    buttonShadow: [],
  );

  static SabhaColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// One zikr at a time with a big count button. When a zikr's count is
/// finished it moves on to the next unfinished one by itself.
///
/// Needs an [AzkarProgressCubit] (the section's, shared with the azkar
/// page) and a [SabhaCubit] above it.
class SabhaScreen extends StatefulWidget {
  const SabhaScreen({super.key, required this.title, required this.azkarList});
  final String title;
  final List<AzkarModel> azkarList;

  @override
  State<SabhaScreen> createState() => _SabhaScreenState();
}

class _SabhaScreenState extends State<SabhaScreen> {
  // «تمّ ✓ — الذكر التالي» is a moment, not state: shown for 1.4 s after
  // the sabha moves on by itself.
  String _flash = '';
  Timer? _flashTimer;

  List<AzkarModel> get _azkar => widget.azkarList;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _showFlash() {
    _flashTimer?.cancel();
    setState(() => _flash = 'تمّ ✓ — الذكر التالي');
    _flashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _flash = '');
    });
  }

  void _clearFlash() {
    _flashTimer?.cancel();
    if (_flash.isNotEmpty) setState(() => _flash = '');
  }

  void _increment() {
    final finished = context.read<SabhaCubit>().increment();
    if (finished) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _reset() {
    _clearFlash();
    context.read<SabhaCubit>().resetCurrent();
  }

  void _restartAll() {
    _clearFlash();
    context.read<SabhaCubit>().restartAll();
  }

  void _go(int delta) {
    _clearFlash();
    context.read<SabhaCubit>().go(delta);
  }

  @override
  Widget build(BuildContext context) {
    final c = SabhaColors.of(context);
    final allDone = context.select(
      (AzkarProgressCubit cubit) => cubit.state.allDone,
    );
    return BlocListener<SabhaCubit, SabhaState>(
      listenWhen: (prev, next) => next.finishedCount > prev.finishedCount,
      listener: (context, _) => _showFlash(),
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: c.muted),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title, style: AppText.title.copyWith(color: c.ink)),
              Text(
                'وضع السبحة',
                style: AppText.caption.copyWith(color: c.muted),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: allDone ? _buildDone(c) : _buildCounter(c),
        ),
      ),
    );
  }

  Widget _buildCounter(SabhaColors c) {
    final index = context.watch<SabhaCubit>().state.index;
    final progress = context.watch<AzkarProgressCubit>().state;
    final zikr = _azkar[index];
    final target = zikr.repetition;
    final done = progress.countedOf(index);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s5,
        AppSpace.s2,
        AppSpace.s5,
        AppSpace.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The zikr. Long ones scroll inside the card.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: Container(
              decoration: BoxDecoration(
                color: c.raised,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: c.line),
              ),
              child: SingleChildScrollView(
                key: ValueKey(index),
                padding: const EdgeInsets.all(AppSpace.s5),
                child: Column(
                  children: [
                    if (zikr.aboveContent != null &&
                        zikr.aboveContent!.trim().isNotEmpty) ...[
                      Text(
                        zikr.aboveContent!,
                        textAlign: TextAlign.center,
                        style: AppText.zikrLead.copyWith(color: c.goldInk),
                      ),
                      const SizedBox(height: AppSpace.s2),
                    ],
                    Text(
                      zikr.content,
                      textAlign: TextAlign.center,
                      style: AppText.zikr.copyWith(
                        fontSize: 26,
                        height: 48 / 26,
                        fontWeight: FontWeight.w700,
                        color: c.zikr,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s4),

          // Previous / position / next. In RTL the first child is on the
          // right. The back/forward icons mirror with the text direction,
          // like the app bar's back button, so "previous" points right.

          // The count, in a ring that fills up to the target.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    child: _CountRing(done: done, target: target, colors: c),
                  ),
                ),
                const SizedBox(height: AppSpace.s2),
                SizedBox(
                  height: 20,
                  child: Text(
                    _flash,
                    style: AppText.label.copyWith(color: c.accent),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: 'الذكر السابق',
                colors: c,
                onPressed: index > 0 ? () => _go(-1) : null,
              ),
              Expanded(
                child: Text(
                  'الذكر ${index + 1} من ${_azkar.length}',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                    color: c.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _RoundIconButton(
                icon: Icons.arrow_forward_ios_rounded,
                tooltip: 'الذكر التالي',
                colors: c,
                onPressed: index < _azkar.length - 1 ? () => _go(1) : null,
              ),
            ],
          ),
          // Count button in the middle, reset beside it.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 56),
              const SizedBox(width: AppSpace.s6),
              Semantics(
                button: true,
                label: 'تسبيحة',
                onTap: _increment,
                excludeSemantics: true,
                child: Material(
                  color: c.accent,
                  shape: const CircleBorder(),
                  shadowColor: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _increment,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: c.buttonShadow,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 48,
                        color: c.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s6),
              Tooltip(
                message: 'تصفير عداد هذا الذكر',
                child: OutlinedButton(
                  onPressed: done > 0 ? _reset : null,
                  style: OutlinedButton.styleFrom(
                    fixedSize: const Size(56, 56),
                    minimumSize: const Size(56, 56),
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    foregroundColor: c.muted,
                    side: BorderSide(color: c.lineStrong),
                  ),
                  child: const Icon(Icons.restart_alt_rounded, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDone(SabhaColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.goldSoft,
                border: Border.all(color: c.gold, width: 2),
              ),
              child: Icon(Icons.check_rounded, size: 56, color: c.goldInk),
            ),
            const SizedBox(height: AppSpace.s4),
            Text(
              'تمّ القسم كله',
              style: AppText.title.copyWith(fontSize: 28, color: c.ink),
            ),
            const SizedBox(height: AppSpace.s1),
            Text('تقبّل الله.', style: AppText.body.copyWith(color: c.muted)),
            const SizedBox(height: AppSpace.s5),
            Wrap(
              spacing: AppSpace.s3,
              runSpacing: AppSpace.s3,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.onAccent,
                    minimumSize: const Size(0, 48),
                    textStyle: AppText.label,
                  ),
                  child: const Text('رجوع للقائمة'),
                ),
                OutlinedButton(
                  onPressed: _restartAll,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.ink,
                    side: BorderSide(color: c.lineStrong),
                    minimumSize: const Size(0, 48),
                    textStyle: AppText.label,
                  ),
                  child: const Text('من جديد'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountRing extends StatelessWidget {
  const _CountRing({
    required this.done,
    required this.target,
    required this.colors,
  });
  final int done;
  final int target;
  final SabhaColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final progress = target == 0 ? 0.0 : math.min(done / target, 1.0);
    return Semantics(
      label: '$done من $target',
      liveRegion: true,
      excludeSemantics: true,
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                backgroundColor: c.track,
                color: c.accent,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$done',
                  style: AppText.display.copyWith(
                    fontSize: 80,
                    height: 88 / 80,
                    color: c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'من $target',
                  style: AppText.body.copyWith(color: c.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.colors,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final SabhaColors colors;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      iconSize: 20,
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        backgroundColor: c.raised,
        foregroundColor: c.ink,
        disabledBackgroundColor: c.raised.withValues(alpha: 0.5),
        disabledForegroundColor: c.muted.withValues(alpha: 0.5),
        side: BorderSide(color: c.line),
      ),
    );
  }
}
