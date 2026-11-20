import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_guide/core/app/app_info.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/core/custom_widgets/custom_appbar/custom_appbar.dart';
import 'package:my_guide/core/custom_widgets/custom_screen/custom_screen.dart';
import 'package:my_guide/feature/app_version/cubit/app_version_cubit.dart';

/// «عن التطبيق»: the app's name and installed version, what's new in it,
/// and the download link with a QR code to share it.
class AppVersion extends StatefulWidget {
  const AppVersion({super.key});

  @override
  State<AppVersion> createState() => _AppVersionState();
}

class _AppVersionState extends State<AppVersion> {
  @override
  void initState() {
    super.initState();
    // Seen: the home badge goes back to normal.
    context.read<AppVersionCubit>().markSeen();
  }

  Future<void> _openLink() async {
    final opened = await launchUrl(
      Uri.parse(AppInfo.downloadUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مقدرناش نفتح الرابط. انسخه وافتحه بنفسك.')),
      );
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(const ClipboardData(text: AppInfo.downloadUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الرابط')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    final version = context.watch<AppVersionCubit>().state;
    final notes = AppInfo.releaseNotes
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return CustomScreen(
      appBar: const CustomAppBar(title: 'عن التطبيق'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpace.s6),
        children: [
          // Name and version.
          _Panel(
            child: Column(
              children: [
                Text(
                  AppInfo.name,
                  style: AppText.title.copyWith(
                    fontSize: 34,
                    height: 48 / 34,
                    color: c.primary,
                  ),
                ),
                Text(
                  AppInfo.tagline,
                  style: AppText.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: AppSpace.s3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s3,
                    vertical: AppSpace.s1,
                  ),
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    version.buildNumber.isEmpty
                        ? 'الإصدار ${version.version}'
                        : 'الإصدار ${version.version} (${version.buildNumber})',
                    style: AppText.label.copyWith(color: c.primary),
                  ),
                ),
              ],
            ),
          ),

          if (notes.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s4),
            _Panel(
              crossAxisAlignment: CrossAxisAlignment.start,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الجديد في هذا الإصدار',
                    style: AppText.heading.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: AppSpace.s2),
                  for (final line in notes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.s1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 9),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: c.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.s2),
                          Expanded(
                            child: Text(
                              line,
                              style: AppText.body.copyWith(color: c.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Download: QR, link, open and copy.
          const SizedBox(height: AppSpace.s4),
          _Panel(
            child: Column(
              children: [
                Text(
                  'حمّل آخر نسخة',
                  style: AppText.heading.copyWith(color: c.ink),
                ),
                const SizedBox(height: AppSpace.s1),
                Text(
                  'امسح الكود من موبايل تاني، أو ابعت الرابط لحد',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: AppSpace.s4),
                // Always dark on white, in both themes, so every scanner
                // can read it.
                Semantics(
                  image: true,
                  label: 'كود QR لرابط تحميل وِرْد',
                  child: Container(
                    padding: const EdgeInsets.all(AppSpace.s3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: c.line),
                    ),
                    child: QrImageView(
                      data: AppInfo.downloadUrl,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0B3D35),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0B3D35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s3),
                SelectableText(
                  AppInfo.downloadUrl,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: AppText.caption.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: AppSpace.s4),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _openLink,
                        style: FilledButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: c.onPrimary,
                          minimumSize: const Size(0, 48),
                          textStyle: AppText.label,
                        ),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('افتح رابط التحميل'),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s3),
                    OutlinedButton.icon(
                      onPressed: _copyLink,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.primary,
                        side: BorderSide(color: c.lineStrong),
                        minimumSize: const Size(0, 48),
                        textStyle: AppText.label,
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      label: const Text('نسخ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A raised card section.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });
  final Widget child;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return Container(
      padding: const EdgeInsets.all(AppSpace.s5),
      alignment: crossAxisAlignment == CrossAxisAlignment.start
          ? AlignmentDirectional.centerStart
          : Alignment.center,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: c.cardShadow,
      ),
      child: child,
    );
  }
}
