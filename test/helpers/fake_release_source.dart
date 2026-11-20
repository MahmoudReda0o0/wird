import 'package:my_guide/features/about/data/release_info.dart';
import 'package:my_guide/features/about/data/release_source.dart';

/// Answers [release] as the latest published version; null means offline.
class FakeReleaseSource implements ReleaseSource {
  const FakeReleaseSource(this.release);
  final ReleaseInfo? release;

  @override
  Future<ReleaseInfo?> latest() async => release;
}
