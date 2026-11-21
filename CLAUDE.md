# وِرْد (Wird) — ملخص المشروع للشغل في Claude Code

> Claude Code بيقرا الملف ده لوحده في أول كل جلسة. حدّثه لما حاجة مهمة تتغير.
> آخر تحديث: 21 نوفمبر 2026. النسخة على `main` هي `1.0.0+2`.

## المشروع
- **⚠️ Android بس دلوقتي.** مش هنشتغل على iOS خالص لحد ما Mahmoud يقول. ما تعملش أي حاجة تخص الآيفون: لا ملفات في `ios/`، ولا `Info.plist`، ولا pods، ولا أصوات `.caf`، ولا تجارب على iOS، ولا قرارات تصميم أو packages عشان خاطر iOS. لو feature محتاجة حاجة على iOS، اكتبها في الـ PR كـ «مؤجل لـ iOS» وكمّل Android. الإعدادات اللي موجودة دلوقتي في `ios/` (أقل نسخة 15، والأصوات، و`NSMotionUsageDescription`) تفضل زي ما هي، بس ما تتعدّلش.
- تطبيق Flutter عربي (RTL) للأذكار ومواقيت الصلاة. الـ repo: `MahmoudReda0o0/wird`. اسم الـ Dart package `my_guide`، ومش هنغيّره دلوقتي.
- الـ App ID `com.mahmoudreda.wird` على Android وiOS، والاسم الظاهر «وِرْد». النسخة الحالية `1.0.0+2`.
- التصميم (Claude Design canvas): https://claude.ai/artifact/GUnUgbYYBFF7WRFV5giQX5. فيه الهوم (فاتح وغامق وبعد العشاء)، وإضافات الـ design system، وصفحة الأذكار، ووضع السبحة.
- الـ Design System «Wird»: https://claude.ai/artifact/2fwNvazQhYq3XrKv7VCqsK. فيه الـ tokens والـ components: AppBar، MenuTile، ZikrCard، PrayerTimes، ThemeToggle.
- طريقة الشغل والـ branches في قسم «طريقة الشغل» تحت. الخلاصة: كل الشغل بيتجمّع على `main`، و`new_version` هو اللي بيوصّل النسخة للناس.

## الـ Stack
Flutter (Dart `^3.12.1`)، و`flutter_bloc` للحالة، و`shared_preferences`، و`adhan_dart` لحساب المواقيت، و`timezone`، و`flutter_local_notifications` 22.x للأذان، و`package_info_plus`، و`url_launcher`، و`qr_flutter`، والخطوط جوه التطبيق في `assets/fonts/`: IBM Plex Sans Arabic للواجهة، وNoto Naskh Arabic لنص الأذكار. ومفيش `google_fonts`.

## الـ Architecture
- **الـ structure:** feature-first. `lib/app/` فيه `bootstrap.dart` و`app.dart` و`router/`، و`lib/core/` فيه `theme/` و`widgets/` و`time/` (`AppClock`: الوقت دايمًا بتوقيت القاهرة) و`notifications/` (`NotificationScheduler`، المكان الوحيد اللي بيكلّم plugin الإشعارات)، ومش بيعمل import لأي feature، و`lib/features/<name>/` فيه `data/` و`cubit/` و`view/` و`widgets/`. التيستات في `test/features/<name>/`. الـ imports ماشية في اتجاه واحد: view ثم cubit ثم data ثم core. التفاصيل في README («Project layout»).
- `app/bootstrap.dart` بيقرا `SharedPreferences` و`PackageInfo` مرة واحدة، وبيعمل الـ Cubits العامة، و`app/app.dart` بيوصّلها بـ `MultiBlocProvider`. فيه كمان `MultiBlocListener` بيعيد جدولة الأذان لما `CityCubit` أو `AdhanCubit` يتغيّر.
- الـ Cubits:
  | Cubit | الحالة | مكانه |
  |---|---|---|
  | `ThemeCubit` (`core/theme`) | `ThemeMode`، key: `theme_mode` | root |
  | `CityCubit` (`features/prayer_times/cubit`) | `PrayerCity`، key: `prayer_city` | root |
  | `AdhanCubit` (`features/adhan/cubit`) | `AdhanSettings`، keys: `adhan_enabled` و`adhan_prayers`. بيطلب الإذن عن طريق `requestPermission` اللي بيتباصى له | root |
  | `AppVersionCubit` (`features/about/cubit`) | النسخة و`isNew`، key: `app_version_seen` | root |
  | `QiblaCubit` (`features/qibla/cubit`) | اتجاه الموبايل والقبلة، والمعايرة، والحديد القريب، والشمس، ويوم الشمس فوق الكعبة | شاشة القبلة |
  | `AzkarProgressCubit` (`features/azkar/cubit`) | العدد الباقي لكل ذكر، ومحفوظ لليوم (`AzkarProgress`) | كل صفحة أذكار، وهو نفس الـ instance اللي السبحة بتستخدمه |
  | `SabhaCubit` (`features/azkar/cubit`) | الذكر الظاهر، و`finishedCount` عشان رسالة «تمّ ✓» | شاشة السبحة |
- اللوجيك الصافي، ومن غير Flutter state: `PrayerTimingData` فيه `forDay` و`next` و`window` و`format` و`countdown` و`dateLabel`، و`AdhanPlan.plan()`، و`AzkarProgress` للتخزين. الشاشات بتعيد الحساب من الـ state الحالي مع كل tick.
- الـ Theme: `context.wird` للألوان (`WirdColors`)، و`AppText` و`AppSpace` و`AppRadius` في `core/theme/app_theme.dart`. ممنوع أي hex في الشاشات، ما عدا `SabhaColors` (ألوان السبحة الهادية) والـ QR.

## اللي اتعمل (PRs من #1 لـ #7، كلهم اتعملهم merge)
1. **#2 إصلاحات المراجعة:**
   - العصر بقى بطريقة الهيئة المصرية العامة للمساحة مع المذهب الشافعي (كان MWL وحنفي).
   - اختيار مدينة من 27 مدينة مصرية.
   - فجر بكرة بيظهر بعد العشاء، والشاشة بتتحدّث لوحدها بعد نص الليل.
   - عدّ الأذكار بيتحفظ لليوم، ومعاه progress وزرار «من جديد».
   - الاسم والـ ID اتغيّروا، والتنضيف، والـ tests، والـ README.
2. **#3 وضع السبحة:**
   - زرار السبحة (`SabhaIcon` مرسوم) تحت على اليمين في كل صفحة أذكار.
   - ذكر واحد في الشاشة، والعداد هدفه تكرار الذكر نفسه، ولما يخلص بينقل للذكر اللي بعده لوحده ويتخطى اللي خلص.
   - أسهم للتنقل، والتصفير بيصفّر الذكر الحالي بس، وشاشة «تمّ القسم كله».
   - ألوان هادية خاصة بالشاشة دي.
3. **#4 الهوم الجديد:**
   - `NextPrayerCard`: عدّاد HH:MM:SS بيتحدّث كل ثانية، وشريط من الصلاة اللي فاتت للجاية.
   - Grid عمودين من `HomeGridTile`.
   - زرار المدينة.
4. **#5 الأذان:**
   - switch في شاشة المواقيت، وجرس لكل صلاة، وchip في كارت الهوم بتفتح شاشة المواقيت.
   - الأذان بيتجدول 10 أيام قدام.
   - صوت للفجر وصوت لباقي الصلوات:
     - Android: `res/raw/adhan.mp3` و`adhan_fajr.mp3`، و`keep.xml`، والـ channels `adhan_v1` و`adhan_fajr_v1`.
     - iOS: `adhan.caf` و`adhan_fajr.caf`، أول 30 ثانية مع fade، ومتضافين للـ Runner target.
   - الـ manifest فيه الـ permissions والـ receivers، والـ desugaring متفعّل، و`minSdk` بقى 24 على الأقل.
5. **`c861914` (Mahmoud):** إصلاحات بعد التشغيل الأول:
   - ترتيب السبحة بقى: الذكر، وبعده الحلقة، وبعدها الأسهم، وبعدها الأزرار.
   - إصلاح type.
6. **#6 Bloc:** كل الـ `ValueNotifier` controllers اتنقلت لـ Cubits، ومعاها tests.
7. **`9d338f1` + #7 النسخة:**
   - `VersionBadge` جنب عنوان الهوم: بيتلوّن دهبي ومكتوب عليه «جديد» بعد التحديث، لحد ما المستخدم يفتح «عن التطبيق».
   - شاشة `AppVersion`: الاسم، والإصدار، و`AppInfo.releaseNotes`، ولينك الدرايف مع QR وزرار فتح وزرار نسخ.

## ⚠️ التيستات والـ CI: بس لما Mahmoud يطلب
- ما تكتبش تيستات جديدة، وما تستناش الـ CI أو تتابعه، غير لما Mahmoud يقول. التعديلات الصغيرة بتتعمل وتتعمل push على طول.
- الـ CI بيشتغل لوحده على أي push على `main`، بس ما تقعدش تستنّاه.
- **فكّر Mahmoud** قبل الـ merge لو الشغل كان خطوات كتير أو feature جديدة: «نعمل تيستات ونستنى الـ CI قبل الـ merge؟». والقرار ليه.

## ⚠️ مهم: أغلب الكود اتكتب من غير ما يتبني
الكود من #2 لـ #7 اتكتب في بيئة مفيهاش Flutter. **أول حاجة في Claude Code:**
```
flutter pub get && flutter analyze && flutter test
```
صلّح أي error قبل ما تبدأ أي feature. التيستات في `test/features/`، وبتغطي: المواقيت، و`AdhanPlan`، والـ Cubits، والسبحة، وتقدم الأذكار، والنسخة.

## المطلوب، بالأولوية
1. **تأكد إن الأساس سليم:** `analyze` و`test` و`run` على موبايل حقيقي. جرّب الأذان، وزرار السبحة، والـ badge الدهبي: غيّر `version:` لـ `1.0.1+2` وشغّل تاني.
2. ~~**CI**~~ ✅ `.github/workflows/ci.yml`: بيشغّل `flutter pub get` و`flutter analyze` و`flutter test` على كل PR وكل push على `main`، على **Flutter 3.44.1** (نفس نسخة المشروع). لازم يبقى أخضر قبل أي merge. ابتداءً من Flutter 3.47، `package:flutter/material.dart` بقى deprecated لصالح `package:material_ui`، فالترقية ليها PR لوحدها: غيّر `flutter-version` في الـ workflow، ونقل الـ imports في نفس الـ PR.
3. ~~**الخطوط جوه التطبيق**~~ ✅ `google_fonts` اتشال. الخطوط في `assets/fonts/` ومتعرّفة في `pubspec.yaml`: الواجهة بـ `IBMPlexSansArabic` (400 و500 و600)، والأذكار بـ `NotoNaskhArabic` (400 و500 و600 و700). Mahmoud اختار Noto Naskh بعد مقارنة مع Amiri وScheherazade New، والمقارنة في الكانفاس «Wird — مقارنة خطوط الأذكار». أوزان Noto الثابتة مقطوعة من الملف الـ variable بـ `fontTools`، والرخص (OFL) بتظهر في صفحة الرخص عن طريق `LicenseRegistry` في `bootstrap.dart`.
4. ~~**تنضيف**~~ ✅ اتعمل على `chore/cleanup`: اتشال `flutter_screenutil` و`navigatorKey`، واتمسح `MainActivity.kt` القديم، واتضافت الـ lints الـ 3، و`flutter analyze` بقى «No issues found».
5. ~~**الأذان في الخلفية والتحديثات**~~ ✅ على `feature/background-refresh`:
   - `app/background_refresh.dart` (Android بس، `workmanager`): task يومية بتعيد جدولة الأذان، وtask كل 6 ساعات بشرط النت بتقرا `latest.json` ولو فيه نسخة أحدث بتطلع إشعار «نسخة جديدة من وِرْد» مرة واحدة لكل نسخة (key: `update_notified`).
   - `UpdateChecker` (`features/about/cubit`): بيشيك عند الفتح، وتاني لما التطبيق يرجع للـ foreground لو آخر شيك ناجح أقدم من 30 دقيقة، وبيعيد كل دقيقتين طول ما الشيك فاشل (مفيش نت) والتطبيق مفتوح.
   - «يأذّن والموبايل صامت» (`AdhanSettings.asAlarm`، key: `adhan_as_alarm`): channels جديدة `adhan_alarm_v1` و`adhan_fajr_alarm_v1` بـ `AudioAttributesUsage.alarm`. على iOS مش متاح (محتاج critical alerts من Apple).
   - الـ CI فيه job تاني «Build APK (debug)» عشان أخطاء Gradle والـ plugins تبان في الـ PR.
6. **تذكير بالأذكار:** الصباح بعد الفجر، والمساء بعد العصر، وتنبيه قبل الأذان بـ 10 دقايق. ده بيستخدم نفس الـ notifications.
7. **وضع رمضان والتاريخ الهجري** قبل رمضان، حوالي أوائل فبراير 2027: الإمساك، والعدّ للسحور والإفطار.
8. **النشر على Google Play:** keystore و`key.properties` (مش في git)، و`signingConfig` للـ release، والأيقونة، والـ screenshots، والـ privacy policy.
9. **بعد النشر:** Home widget لأقرب صلاة (`home_widget`)، وتحديد المكان بالـ GPS، وإحصائيات وأيام متتالية للأذكار، ومفضلة وبحث.

## حاجات Manual على Mahmoud
- امسح الـ branches القديمة: `feature/light-dark-theme`، `fix/review-issues`، `sabha`، `feature/new-home`، `feature/adhan`، `refactor/bloc`، `feature/app-version`.
- شيّر فولدر الدرايف `15sMC3pU1w12yFQQIKqurSKqujRBF9dhY` كـ «Anyone with the link».
- حدّث الـ Wird Design System بـ `NextPrayerCard` و`HomeGridTile`، والستايلين `countdown` و`hero`، وألوان السبحة. التفاصيل في board «Design System — الإضافات الجديدة» على الكانفاس، لأني ما قدرتش أعدّل الـ design system من الشات.

## طريقة الشغل
فيه branchين ليهم معنى:

| Branch | دوره |
|---|---|
| `main` | كل الشغل بيتجمّع عليه. أي تعديل بيتعمل على `main` على طول، أو على branch جانبي (زي `feature/...` أو `fix/...`) وبعدين يتعمله merge في `main`. |
| `new_version` | النسخة اللي وصلت للناس. التطبيق المتسطّب بيقرا `release/latest.json` من هنا كل ما يفتح (`AppInfo.latestReleaseUrl`). مفيش حد بيشتغل عليه مباشرة: بيتحرّك بس لـ commit على `main` اتعمله release. |

**الدورة:**
1. **الشغل:** التعديلات بتتعمل على `main` أو على branch جانبي. الـ branch الجانبي بيتعمله merge في `main` لما يخلص، وبعدها يتمسح. التيستات والـ CI بس لما Mahmoud يطلب (القسم «التيستات والـ CI» فوق).
2. **ثبات:** قبل أي release، `main` لازم يبقى مستقر: الـ analyze نضيف، والتيستات كلها عدّت، والـ APK اتجرّب على موبايل حقيقي. لو حاجة مش مستقرة، الـ release يستنّى. وما بنغيّرش رقم النسخة في نص الشغل.
3. **Release** (بس لما Mahmoud يقول إن كل حاجة مستقرة):
   1. زوّد `version:` في `pubspec.yaml`. تعديل صغير أو إصلاح بيزوّد الـ build بس (`1.0.0+2` بتبقى `1.0.0+3`)، وأي feature جديد بيزوّد الرقم نفسه (`1.0.0+2` بتبقى `1.1.0+3`). والـ build بيزيد دايمًا.
   2. اكتب الجديد في `AppInfo.releaseNotes` (`lib/features/about/data/app_info.dart`)، كل تعديل في سطر، وحط نفس السطور في `release/latest.json` مع الـ `version` والـ `build`.
   3. اعمل commit على `main`: «Release x.y.z+n».
   4. `flutter build apk --release`، وارفع الـ APK على فولدر الدرايف (`AppInfo.downloadUrl`).
   5. **بعد ما الـ APK يترفع بس:** `git push origin main` وبعدها `git push origin main:new_version`. من اللحظة دي، أي حد عنده نسخة أقدم هيشوف «تحديث» وزرار التنزيل. GitHub ممكن ياخد كام دقيقة لحد ما يحدّث الملف.
4. **ممنوع** تعمل push لـ `new_version` قبل ما الـ APK يبقى على الدرايف، لأن الناس هتتنبّه بنسخة مش موجودة. وممنوع تعمل push لـ commit مش مستقر، أو push من غير ما Mahmoud يطلب.

## Gotchas
- **المواقيت:** `CalculationMethodParameters.egyptian()..madhab = Madhab.shafi`. الـ `date` بيتباصى الساعة 12 الضهر، عشان اليوم يفضل صح سواء المكتبة قرأته local أو UTC. والتوقيت دايمًا `Africa/Cairo`، والـ zone بتاعها بيتجاب من `PrayerTimingData.cairo`.
- **`flutter_local_notifications` 22:** الـ parameters كلها named، زي `initialize(settings:)` و`zonedSchedule(id:, title:, body:, scheduledDate:, notificationDetails:, androidScheduleMode:)`.
- **الإشعارات:** كل feature ليه نطاق ids في `core/notifications/notification_ids.dart`، والأذان واخد 1000–1999، وإشعار التحديث 9000. أي feature بيلغي النطاق بتاعه بس بـ `cancelRanges`، وممنوع `cancelAll`. الشاشات اللي بتعمل Cubit بنفسها بتاخد الـ prefs من `context.read<SharedPreferences>()`.
- **صوت الـ channel على Android:** بيتثبّت أول ما الـ channel يتعمل. لو غيّرت ملف صوت، غيّر الـ channel id معاه (`adhan_v2`).
- **iOS (مؤجل، مرجع بس):** صوت الإشعار أقصاه 30 ثانية، والصيغة لازم caf أو wav أو aiff مش mp3.
- **الـ Native splash:** خلفية بيضا، وفي النص السبحة (`SabhaIcon`) بلون الـ primary، والكلام ده في الوضع الفاتح والغامق. الإعدادات في آخر `pubspec.yaml` (`flutter_native_splash`). الصور في `assets/splash/`، وبتتعمل بـ `flutter test tool/render_splash_test.dart`. بعد أي تعديل شغّل `dart run flutter_native_splash:create`، وما تعدّلش ملفات الـ splash في android/ios بإيدك.
- **القبلة:** من إحداثيات المدينة المختارة (مفيش GPS). البوصلة `true_compass` (شمال حقيقي من موديل WMM2025) ورا `HeadingSource`، فلو حبيت تبدّل الـ package غيّر `DeviceHeadingSource` بس. ده خلّى أقل نسخة iOS بقت **15**. تحذير الحديد من `sensors_plus` على Android بس. التصميم في كانفاس «Wird — القبلة»: https://claude.ai/artifact/RpBu25V8JMBVydr7ixRWgQ. الخطة والـ design في `docs/superpowers/`.
- **Widget tests والـ Cubits اللي بتسمع لـ streams:** اقفل الـ Cubit جوه جسم التيست نفسه، مش في `tearDown` (بيعلّق)، وما تعملش `await` على `cancel()` للـ subscriptions في `close()`.
- **RTL:** `Icons.arrow_back_ios_new_rounded` و`arrow_forward_ios_rounded` بيتعكسوا لوحدهم. في الـ RTL، الـ `startFloat` بيبقى على اليمين.
- **`math.min` و`math.max`** بيرجّعوا `num`. في العدّ استخدم `countedOf()`، اللي بيرجّع `int`.
- **الـ tests:** استخدم `SharedPreferences.setMockInitialValues`. الـ widget tests شغّالة: استخدم `testApp()` و`TestCubits` و`mockPrefs()` و`usePhoneSize()` من `test/helpers/test_app.dart`. الخطوط ما بتتحمّلش في التيستات، فالنص بيظهر بخط التيست، وده عادي. خط التيست أعرض من الحقيقي، فأي overflow بيطلع في التيست بيبقى حقيقي مع النص الكبير (accessibility) أو الموبايل الضيق.
- **الـ commits:** رسايل واضحة. تقدر تشتغل على `main` على طول، أو على branch جانبي وبعدين تعمله merge في `main`. و`new_version` ما بيتحرّكش غير في الـ release (قسم «طريقة الشغل»).
