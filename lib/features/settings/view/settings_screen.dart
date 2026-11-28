import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_guide/app/router/app_routes.dart';
import 'package:my_guide/core/theme/app_theme.dart';
import 'package:my_guide/core/theme/theme_cubit.dart';
import 'package:my_guide/core/widgets/custom_appbar.dart';
import 'package:my_guide/core/widgets/custom_screen.dart';
import 'package:my_guide/features/about/data/app_info.dart';
import 'package:my_guide/features/adhan/cubit/adhan_cubit.dart';
import 'package:my_guide/features/adhan/data/adhan_settings.dart';
import 'package:my_guide/features/prayer_times/cubit/city_cubit.dart';
import 'package:my_guide/features/prayer_times/widgets/prayer_city_picker.dart';
import 'package:my_guide/features/settings/cubit/settings_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

/// الإعدادات: the look, notifications, the city, reading and counting,
/// and the app itself.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final adhan = context.watch<AdhanCubit>().state;
    final city = context.watch<CityCubit>().state;
    final prefs = context.watch<SettingsCubit>().state;
    return CustomScreen(
      appBar: const CustomAppBar(title: 'الإعدادات'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpace.s6),
        children: [
          const _SectionTitle('المظهر'),
          _Card(
            children: [
              _ChoiceRow<ThemeMode>(
                icon: Icons.palette_outlined,
                title: 'الثيم',
                value: themeMode,
                choices: const {
                  ThemeMode.light: 'فاتح',
                  ThemeMode.dark: 'غامق',
                  ThemeMode.system: 'زي الموبايل',
                },
                onChanged: context.read<ThemeCubit>().setMode,
              ),
            ],
          ),
          const _SectionTitle('الإشعارات'),
          _Card(
            children: [
              _SwitchRow(
                icon: adhan.appNotifications
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                title: 'إشعارات التطبيق',
                subtitle: adhan.appNotifications
                    ? 'الأذان والتنبيهات شغالة حسب إعداداتها'
                    : 'كل إشعارات وِرْد مقفولة',
                value: adhan.appNotifications,
                onChanged: (on) => _setNotifications(context, on),
              ),
              const _Divider(),
              _LinkRow(
                icon: Icons.mosque_outlined,
                title: 'إعدادات الأذان',
                subtitle: _adhanSummary(adhan),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.prayerTiming),
              ),
            ],
          ),
          const _SectionTitle('المدينة'),
          _Card(
            children: [
              _LinkRow(
                icon: Icons.location_on_outlined,
                title: 'مدينة المواقيت',
                subtitle: city.name,
                onTap: () => showPrayerCityPicker(context),
              ),
            ],
          ),
          const _SectionTitle('الأذكار'),
          _Card(
            children: [
              _ChoiceRow<double>(
                icon: Icons.format_size_rounded,
                title: 'حجم خط الأذكار',
                value: prefs.zikrScale,
                choices: const {0.85: 'صغير', 1.0: 'عادي', 1.2: 'كبير'},
                onChanged: context.read<SettingsCubit>().setZikrScale,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s4,
                  0,
                  AppSpace.s4,
                  AppSpace.s4,
                ),
                child: Text(
                  'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
                  textAlign: TextAlign.center,
                  style: AppText.zikr.copyWith(
                    color: context.wird.ink,
                    fontSize: AppText.zikr.fontSize! * prefs.zikrScale,
                  ),
                ),
              ),
              const _Divider(),
              _SwitchRow(
                icon: Icons.vibration_rounded,
                title: 'اهتزاز السبحة',
                subtitle: 'اهتزاز خفيف مع كل عدّة',
                value: prefs.sabhaHaptics,
                onChanged: context.read<SettingsCubit>().setSabhaHaptics,
              ),
            ],
          ),
          const _SectionTitle('التطبيق'),
          _Card(
            children: [
              _LinkRow(
                icon: Icons.info_outline_rounded,
                title: 'عن التطبيق',
                subtitle: 'النسخة والجديد فيها',
                onTap: () => Navigator.pushNamed(context, AppRoutes.appVersion),
              ),
              const _Divider(),
              _LinkRow(
                icon: Icons.share_rounded,
                title: 'شارك وِرْد على واتساب',
                subtitle: 'ابعت لينك التحميل لحد',
                onTap: () => _shareOnWhatsApp(context),
              ),
              const _Divider(),
              _LinkRow(
                icon: Icons.link_rounded,
                title: 'نسخ لينك التحميل',
                onTap: () => _copyLink(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _adhanSummary(AdhanSettings a) {
    if (!a.appNotifications) return 'مقفولة من «إشعارات التطبيق»';
    final parts = [
      a.enabled ? 'الأذان شغال' : 'الأذان صامت',
      if (a.early) 'تنبيه قبل الأذان بـ ${a.earlyMinutes} د',
    ];
    return parts.join(' · ');
  }

  static Future<void> _setNotifications(BuildContext context, bool on) async {
    final allowed = await context.read<AdhanCubit>().setAppNotifications(on);
    if (allowed || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'اسمح لوِرْد بالإشعارات من إعدادات الموبايل عشان الأذان يشتغل.',
        ),
      ),
    );
  }

  static String get _shareText =>
      '${AppInfo.name}: ${AppInfo.tagline}\n${AppInfo.downloadUrl}';

  static Future<void> _shareOnWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(_shareText)}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) await _copyLink(context);
  }

  static Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('اتنسخ لينك التحميل')),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpace.s2,
        top: AppSpace.s5,
        bottom: AppSpace.s2,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: AppText.caption.copyWith(
            color: context.wird.inkMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A raised group of rows.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: c.cardShadow,
      ),
      child: Material(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: AppSpace.s4,
    endIndent: AppSpace.s4,
    color: context.wird.line,
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: c.onPrimary,
      activeTrackColor: c.primary,
      secondary: Icon(icon, color: c.primary),
      title: Text(title, style: AppText.heading.copyWith(color: c.ink)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: AppText.body.copyWith(color: c.inkMuted)),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: c.primary),
      title: Text(title, style: AppText.heading.copyWith(color: c.ink)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: AppText.body.copyWith(color: c.inkMuted)),
      // Mirrors in RTL, so it points left (forward).
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: c.inkMuted,
      ),
    );
  }
}

/// A title, then a row of choices (a segmented button) under it.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final Map<T, String> choices;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c.primary),
              const SizedBox(width: AppSpace.s4),
              Expanded(
                child: Text(
                  title,
                  style: AppText.heading.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              segments: [
                for (final e in choices.entries)
                  ButtonSegment(value: e.key, label: Text(e.value)),
              ],
              selected: {value},
              onSelectionChanged: (picked) => onChanged(picked.first),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? c.onPrimary
                      : c.ink,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? c.primary
                      : c.surfaceRaised,
                ),
                side: WidgetStatePropertyAll(BorderSide(color: c.line)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
