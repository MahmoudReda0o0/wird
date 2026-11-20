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

  /// What's new in this version, one line per change. Update it with every
  /// release (together with `version:` in pubspec.yaml). Leave it empty to
  /// hide the section.
  static const releaseNotes = '''
مواقيت الصلاة لـ 27 مدينة مصرية بطريقة الهيئة المصرية العامة للمساحة
عداد تنازلي للصلاة القادمة في الشاشة الرئيسية
صوت الأذان في وقت كل صلاة، وأذان خاص للفجر
الأذكار: الصباح والمساء والتسابيح والنوم والاستيقاظ، مع حفظ التقدم لليوم
وضع السبحة: ذكر واحد في الشاشة وينتقل للي بعده لوحده
الوضع الفاتح والغامق''';
}
