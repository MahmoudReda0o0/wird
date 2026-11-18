import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/feature/model/azkar_model.dart';
import 'package:my_guide/feature/screen/azkar/azkar_progress.dart';

/// What the sabha screen needs from the azkar page.
///
/// [remaining] is the page's own list: the sabha changes it in place and
/// saves it, so both screens always show the same progress.
class SabhaArguments {
  SabhaArguments({
    required this.sectionId,
    required this.title,
    required this.azkarList,
    required this.remaining,
  });
  final String sectionId;
  final String title;
  final List<AzkarModel> azkarList;
  final List<int> remaining;
}

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
      BoxShadow(
        color: Color(0x2922302B),
        blurRadius: 18,
        offset: Offset(0, 6),
      ),
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
class SabhaScreen extends StatefulWidget {
  const SabhaScreen({super.key, required this.args});
  final SabhaArguments args;

  @override
  State<SabhaScreen> createState() => _SabhaScreenState();
}

class _SabhaScreenState extends State<SabhaScreen> {
  late int _index;
  String _flash = '';
  Timer? _flashTimer;

  List<AzkarModel> get _azkar => widget.args.azkarList;
  List<int> get _remaining => widget.args.remaining;

  @override
  void initState() {
    super.initState();
    _index = SabhaLogic.firstOpen(_remaining) ?? 0;
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  bool get _allDone => _remaining.every((r) => r <= 0);

  void _save() => AzkarProgress.save(widget.args.sectionId, _remaining);

  void _showFlash(String text) {
    _flashTimer?.cancel();
    _flash = text;
    _flashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _flash = '');
    });
  }

  void _increment() {
    final step = SabhaLogic.count(_remaining, _index);
    if (step == null) return;
    setState(() {
      if (step.finishedZikr) {
        HapticFeedback.mediumImpact();
        if (step.nextIndex != null) {
          _index = step.nextIndex!;
          _showFlash('تمّ ✓ — الذكر التالي');
        }
      } else {
        HapticFeedback.lightImpact();
      }
    });
    _save();
  }

  void _reset() {
    setState(() {
      _remaining[_index] = _azkar[_index].repetition;
      _flash = '';
    });
    _save();
  }

  void _restartAll() {
    setState(() {
      for (var i = 0; i < _remaining.length; i++) {
        _remaining[i] = _azkar[i].repetition;
      }
      _index = 0;
      _flash = '';
    });
    _save();
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= _azkar.length) return;
    setState(() {
      _index = next;
      _flash = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = SabhaColors.of(context);
    return Scaffold(
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
            Text(
              widget.args.title,
              style: AppText.title.copyWith(color: c.ink),
            ),
            Text(
              'وضع السبحة',
              style: AppText.caption.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: _allDone ? _buildDone(c) : _buildCounter(c),
      ),
    );
  }

  Widget _buildCounter(SabhaColors c) {
    final zikr = _azkar[_index];
    final target = zikr.repetition;
    final done = target - math.max(0, math.min(_remaining[_index], target));

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
                key: ValueKey(_index),
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
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: 'الذكر السابق',
                colors: c,
                onPressed: _index > 0 ? () => _go(-1) : null,
              ),
              Expanded(
                child: Text(
                  'الذكر ${_index + 1} من ${_azkar.length}',
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
                onPressed: _index < _azkar.length - 1 ? () => _go(1) : null,
              ),
            ],
          ),

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
            Text(
              'تقبّل الله.',
              style: AppText.body.copyWith(color: c.muted),
            ),
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

/// The sabha's counting rules, kept apart from the widget so they can be
/// tested.
class SabhaLogic {
  SabhaLogic._();

  /// The first zikr with repetitions left, or null when all are done.
  static int? firstOpen(List<int> remaining) {
    for (var i = 0; i < remaining.length; i++) {
      if (remaining[i] > 0) return i;
    }
    return null;
  }

  /// The next unfinished zikr after [from], wrapping around; null if none.
  static int? nextOpen(List<int> remaining, int from) {
    for (var k = 1; k <= remaining.length; k++) {
      final i = (from + k) % remaining.length;
      if (remaining[i] > 0) return i;
    }
    return null;
  }

  /// Counts one repetition of zikr [index] in [remaining] (changed in
  /// place). Returns null when that zikr was already finished.
  static SabhaStep? count(List<int> remaining, int index) {
    if (remaining[index] <= 0) return null;
    remaining[index]--;
    if (remaining[index] > 0) {
      return const SabhaStep(finishedZikr: false);
    }
    return SabhaStep(
      finishedZikr: true,
      nextIndex: nextOpen(remaining, index),
    );
  }
}

/// What one tap did.
@immutable
class SabhaStep {
  const SabhaStep({required this.finishedZikr, this.nextIndex});

  /// This tap finished the zikr.
  final bool finishedZikr;

  /// Where to go next once a zikr is finished. Null means the whole
  /// section is done.
  final int? nextIndex;
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
