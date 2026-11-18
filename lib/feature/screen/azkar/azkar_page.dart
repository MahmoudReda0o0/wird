import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';
import 'package:my_guide/core/custom_widgets/custom_screen/custom_screen.dart';
import 'package:my_guide/feature/model/azkar_model.dart';
import 'package:my_guide/feature/screen/azkar/azkar_progress.dart';
import 'package:my_guide/feature/screen/azkar/custom_widget/azkar_card.dart';

class AzkarPageArguments {
  /// Stable key used to save this section's progress.
  final String id;
  final List<AzkarModel> azkarList;
  final String title;
  AzkarPageArguments({
    required this.id,
    required this.azkarList,
    required this.title,
  });
}

class AzkarPageScreen extends StatefulWidget {
  const AzkarPageScreen({super.key});

  @override
  State<AzkarPageScreen> createState() => _AzkarPageScreenState();
}

class _AzkarPageScreenState extends State<AzkarPageScreen> {
  late AzkarPageArguments _args;
  late List<int> _defaults;

  /// Repetitions left per zikr. Null until the saved progress is loaded.
  List<int>? _remaining;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _args = ModalRoute.of(context)!.settings.arguments as AzkarPageArguments;
    _defaults = [for (final z in _args.azkarList) z.repetition];
    AzkarProgress.load(_args.id, _defaults).then((counts) {
      if (mounted) setState(() => _remaining = counts);
    });
  }

  void _count(int index) {
    final remaining = _remaining;
    if (remaining == null || remaining[index] <= 0) return;
    setState(() {
      remaining[index]--;
    });
    AzkarProgress.save(_args.id, remaining);
  }

  bool _hasProgress(List<int> remaining) {
    for (var i = 0; i < remaining.length; i++) {
      if (remaining[i] < _defaults[i]) return true;
    }
    return false;
  }

  Future<void> _reset() async {
    final c = context.wird;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.surfaceRaised,
        title: Text(
          'البدء من جديد؟',
          style: AppText.heading.copyWith(color: c.ink),
        ),
        content: Text(
          'سيعود عداد كل الأذكار في هذا القسم إلى البداية.',
          style: AppText.body.copyWith(color: c.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إعادة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final fresh = List.of(_defaults);
    setState(() => _remaining = fresh);
    AzkarProgress.save(_args.id, fresh);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    return CustomScreen(
      appBar: CustomAppBar(title: _args.title),
      body: remaining == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpace.s6),
              itemCount: _args.azkarList.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s3),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _ProgressHeader(
                    done: remaining.where((r) => r <= 0).length,
                    total: remaining.length,
                    canReset: _hasProgress(remaining),
                    onReset: _reset,
                  );
                }
                final index = i - 1;
                return AzkarCard(
                  azkarModel: _args.azkarList[index],
                  index: index + 1,
                  remaining: remaining[index],
                  onCount: () => _count(index),
                );
              },
            ),
    );
  }
}

/// "تم 3 من 31" with a progress bar and a reset button.
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.done,
    required this.total,
    required this.canReset,
    required this.onReset,
  });
  final int done;
  final int total;
  final bool canReset;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final complete = total > 0 && done == total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              complete ? 'تمّ القسم كله' : 'تم $done من $total',
              style: AppText.label.copyWith(
                color: complete ? c.goldInk : c.inkMuted,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: canReset ? onReset : null,
              style: TextButton.styleFrom(
                foregroundColor: c.primary,
                textStyle: AppText.label,
                minimumSize: const Size(0, 40),
              ),
              icon: const Icon(Icons.restart_alt_rounded, size: 20),
              label: const Text('من جديد'),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 6,
            backgroundColor: c.surfaceSunken,
            color: complete ? c.gold : c.primary,
          ),
        ),
      ],
    );
  }
}
