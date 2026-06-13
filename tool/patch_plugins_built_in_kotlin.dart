// Patches Flutter Android plugins in the pub cache for AGP 9 built-in Kotlin.
//
// Run after `flutter pub get`:
//   dart tool/patch_plugins_built_in_kotlin.dart
//
// Re-run after `flutter pub get` if packages are re-downloaded.
import 'dart:io';

const _pluginNames = [
  'receive_sharing_intent',
  'shared_preferences_android',
  'url_launcher_android',
];

void main() {
  final lockFile = File('pubspec.lock');
  if (!lockFile.existsSync()) {
    stderr.writeln('pubspec.lock not found. Run from project root after flutter pub get.');
    exit(1);
  }

  final lock = lockFile.readAsStringSync();
  var patched = 0;

  for (final name in _pluginNames) {
    final packageDir = _packageDirFromLock(lock, name);
    if (packageDir == null) {
      stderr.writeln('Skip $name: not found in pubspec.lock');
      continue;
    }

    final androidDir = Directory('$packageDir/android');
    if (!androidDir.existsSync()) {
      stderr.writeln('Skip $name: no android/ at $packageDir');
      continue;
    }

    final kts = File('${androidDir.path}/build.gradle.kts');
    final groovy = File('${androidDir.path}/build.gradle');
    final overrideKts = File('android/gradle/plugin_overrides/$name.build.gradle.kts');
    final overrideGroovy = File('android/gradle/plugin_overrides/$name.build.gradle');

    if (kts.existsSync() && overrideKts.existsSync()) {
      kts.writeAsStringSync(overrideKts.readAsStringSync());
      stdout.writeln('Patched: ${kts.path}');
      patched++;
    } else if (groovy.existsSync() && overrideGroovy.existsSync()) {
      groovy.writeAsStringSync(overrideGroovy.readAsStringSync());
      stdout.writeln('Patched: ${groovy.path}');
      patched++;
    } else {
      stderr.writeln('Skip $name: no matching override file');
    }
  }

  stdout.writeln('Done. Patched $patched plugin(s).');
}

String? _packageDirFromLock(String lock, String packageName) {
  final pattern = RegExp(
    r'  ' + RegExp.escape(packageName) + r':\s*\n(?:[^\n]+\n)*?\s+version: "([^"]+)"',
  );
  final match = pattern.firstMatch(lock);
  if (match == null) return null;

  final version = match.group(1)!;
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) return null;

  return '$home/.pub-cache/hosted/pub.dev/${packageName}-$version';
}
