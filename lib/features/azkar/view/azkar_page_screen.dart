import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/widgets/custom_appbar.dart';
import 'package:my_guide/core/widgets/custom_screen.dart';
import 'package:my_guide/features/azkar/data/models/azkar_model.dart';
import 'package:my_guide/features/azkar/cubit/azkar_progress_cubit.dart';
import 'package:my_guide/features/azkar/cubit/sabha_cubit.dart';
import 'package:my_guide/features/azkar/widgets/azkar_card.dart';
import 'package:my_guide/features/azkar/widgets/sabha_icon.dart';
import 'package:my_guide/features/azkar/view/sabha_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// One azkar section. Provides the section's [AzkarProgressCubit], which
/// the sabha screen shares.
class AzkarPageScreen extends StatelessWidget {
  const AzkarPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as AzkarPageArguments;
    return BlocProvider(
      create: (context) => AzkarProgressCubit(
        prefs: context.read<SharedPreferences>(),
        sectionId: args.id,
        defaults: [for (final z in args.azkarList) z.repetition],
      )..load(),
      child: _AzkarPageView(args: args),
    );
  }
}

class _AzkarPageView extends StatelessWidget {
  const _AzkarPageView({required this.args});
  final AzkarPageArguments args;

  Future<void> _confirmReset(BuildContext context) async {
    final c = context.wird;
    final progress = context.read<AzkarProgressCubit>();
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
    if (confirmed == true) progress.resetAll();
  }

  void _openSabha(BuildContext context) {
    final progress = context.read<AzkarProgressCubit>();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: progress,
          child: BlocProvider(
            create: (_) => SabhaCubit(progress),
            child: SabhaScreen(title: args.title, azkarList: args.azkarList),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final progress = context.watch<AzkarProgressCubit>();
    final state = progress.state;
    final remaining = state.remaining;
    return CustomScreen(
      appBar: CustomAppBar(title: args.title),
      // In RTL "start" is the right-hand side.
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: remaining == null
          ? null
          : FloatingActionButton(
              onPressed: () => _openSabha(context),
              tooltip: 'وضع السبحة',
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              shape: const CircleBorder(),
              child: SabhaIcon(size: 30, color: c.onPrimary),
            ),
      body: remaining == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              // Room at the end so the sabha button never covers the last card.
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: args.azkarList.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s3),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _ProgressHeader(
                    done: state.doneCount,
                    total: remaining.length,
                    canReset: state.hasProgress,
                    onReset: () => _confirmReset(context),
                  );
                }
                final index = i - 1;
                return AzkarCard(
                  azkarModel: args.azkarList[index],
                  index: index + 1,
                  remaining: remaining[index],
                  onCount: () => progress.count(index),
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
