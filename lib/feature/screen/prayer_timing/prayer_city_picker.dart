import 'package:flutter/material.dart';
import 'package:my_guide/core/app/app_theme.dart';
import 'package:my_guide/feature/screen/prayer_timing/prayer_city.dart';

/// Bottom sheet listing the cities; saves the one the user taps.
Future<void> showPrayerCityPicker(BuildContext context) async {
  final c = context.wird;
  final current = PrayerCityController.city.value;
  final picked = await showModalBottomSheet<PrayerCity>(
    context: context,
    backgroundColor: c.surfaceRaised,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView.builder(
        itemCount: PrayerCity.all.length,
        itemBuilder: (context, i) {
          final city = PrayerCity.all[i];
          final selected = city.id == current.id;
          return ListTile(
            title: Text(
              city.name,
              style: AppText.heading.copyWith(
                color: selected ? c.primary : c.ink,
              ),
            ),
            trailing: selected
                ? Icon(Icons.check_rounded, color: c.primary)
                : null,
            onTap: () => Navigator.pop(context, city),
          );
        },
      ),
    ),
  );
  if (picked != null) await PrayerCityController.select(picked);
}

/// The selected city as a chip; tap to choose another.
class PrayerCityChip extends StatelessWidget {
  const PrayerCityChip({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.wird;
    return Semantics(
      button: true,
      label: 'المدينة: $name، اضغط للتغيير',
      excludeSemantics: true,
      onTap: () => showPrayerCityPicker(context),
      child: Material(
        color: c.surfaceRaised,
        shape: StadiumBorder(side: BorderSide(color: c.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showPrayerCityPicker(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: c.primary),
                  const SizedBox(width: AppSpace.s1),
                  Text(name, style: AppText.label.copyWith(color: c.ink)),
                  const SizedBox(width: AppSpace.s1),
                  Icon(Icons.expand_more_rounded, size: 18, color: c.inkMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
