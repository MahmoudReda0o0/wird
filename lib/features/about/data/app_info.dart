/// Facts about the app shown on the «عن التطبيق» screen.
///
/// The version number itself is not here: it's read at runtime from the
/// installed build, so it always matches `version:` in pubspec.yaml.
class AppInfo {
  AppInfo._();

  static const name = 'وِرْد';
  static const tagline = 'أذكار ومواقيت الصلاة';

  /// The Google Drive folder with every release's APK. The folder must be
  /// shared as "Anyone with the link".
  static const downloadUrl =
      'https://drive.google.com/drive/folders/15sMC3pU1w12yFQQIKqurSKqujRBF9dhY';

  /// The branch on GitHub that announces the latest published version.
  /// Push it after uploading a new APK to Drive (see [latestReleaseUrl]).
  static const releaseBranch = 'new_version';

  /// Where the app reads the latest published version: `release/latest.json`
  /// on the [releaseBranch] branch of the public GitHub repo. When its
  /// version is newer than the installed one, the app shows «تحديث» and a
  /// download button that opens [downloadUrl].
  static const latestReleaseUrl =
      'https://raw.githubusercontent.com/MahmoudReda0o0/wird/'
      '$releaseBranch/release/latest.json';

  /// What's new in this version, one line per change. Update it with every
  /// release (together with `version:` in pubspec.yaml). Leave it empty to
  /// hide the section.
  static const releaseNotes = '''
شاشة بداية بيضاء فيها السبحة
تنبيه لما تنزل نسخة جديدة، وزرار «تنزيل النسخة الجديدة» في «عن التطبيق»
الأذان بقى في ميعاده بعد السماح بالمنبّهات الدقيقة
تقدّم الأذكار بيبدأ من جديد صح بعد نص الليل
تحسينات في الشكل مع الخط الكبير والشاشات الصغيرة''';
}
