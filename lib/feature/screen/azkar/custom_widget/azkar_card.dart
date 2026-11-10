import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/feature/model/azkar_model.dart';

/// One zikr. Tapping the card counts one repetition; at zero it turns gold.
class AzkarCard extends StatefulWidget {
  const AzkarCard({super.key, required this.azkarModel, required this.index});
  final AzkarModel azkarModel;
  final int index;
  @override
  State<AzkarCard> createState() => _AzkarCardState();
}

class _AzkarCardState extends State<AzkarCard> {
  static const _duration = Duration(milliseconds: 250);

  bool expanded = false;
  late int counter;

  @override
  void initState() {
    super.initState();
    counter = widget.azkarModel.repetition;
  }

  bool get done => counter <= 0;

  void _count() {
    if (done) return;
    HapticFeedback.lightImpact();
    setState(() => counter--);
  }

  String get _counterLabel {
    if (counter == 1) return 'مرة واحدة';
    if (counter == 2) return 'مرتان';
    if (counter <= 10) return '$counter مرات';
    return '$counter مرة';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final model = widget.azkarModel;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Semantics(
      button: !done,
      label: done ? 'تمّ' : _counterLabel,
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: done ? c.goldSoft : c.surfaceRaised,
          borderRadius: radius,
          border: Border.all(
            color: done ? c.gold : c.line,
            width: done ? 2 : 1,
          ),
          boxShadow: c.cardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: done ? null : _count,
            splashColor: c.primarySoft,
            highlightColor: c.surfaceSunken.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _CounterPill(done: done, label: _counterLabel),
                      const Spacer(),
                      _IndexBadge(index: widget.index),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s2),
                  if (model.aboveContent != null)
                    Text(
                      model.aboveContent!,
                      textAlign: TextAlign.center,
                      style: AppText.zikrLead.copyWith(color: c.goldInk),
                    ),
                  Text(model.content, style: AppText.zikr.copyWith(color: c.ink)),
                  if (model.fadl != null) ...[
                    const SizedBox(height: AppSpace.s2),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => setState(() => expanded = !expanded),
                        style: TextButton.styleFrom(
                          foregroundColor: c.primary,
                          textStyle: AppText.label,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.s2,
                          ),
                          minimumSize: const Size(0, 40),
                        ),
                        icon: AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.expand_more_rounded, size: 20),
                        ),
                        label: const Text('فضل الذكر'),
                      ),
                    ),
                    AnimatedSize(
                      duration: _duration,
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: expanded
                          ? Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: AppSpace.s2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.s4,
                                vertical: AppSpace.s3,
                              ),
                              decoration: BoxDecoration(
                                color: c.surfaceSunken,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              child: Text(
                                model.fadl!,
                                style: AppText.fadl.copyWith(color: c.inkMuted),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Remaining repetitions in teal; a gold check + «تمّ» when finished.
class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.done, required this.label});
  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final fg = done ? c.onGold : c.onPrimary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
      decoration: BoxDecoration(
        color: done ? c.gold : c.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done) ...[
            Icon(Icons.check_rounded, size: 16, color: fg),
            const SizedBox(width: AppSpace.s1),
          ],
          Text(done ? 'تمّ' : label, style: AppText.label.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// The zikr's number, in a small outlined badge.
class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text('$index', style: AppText.caption.copyWith(color: c.inkMuted)),
    );
  }
}
