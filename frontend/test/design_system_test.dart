import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Raw colours may only be written in lib/core/theme/. Everything else uses AppColors tokens.
void main() {
  test('no hard-coded colours outside the theme folder', () {
    final raw = RegExp(r'Color\(0x|(?<![A-Za-z])Colors\.');
    final offenders = <String>[];
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.contains('lib/core/theme/'))
        continue;
      if (raw.hasMatch(file.readAsStringSync())) offenders.add(file.path);
    }
    expect(offenders, isEmpty);
  });
}
