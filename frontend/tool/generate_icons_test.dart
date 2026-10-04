// Generates the app icons from the real Logo widget and the bundled Pinyon Script font.
// Run from frontend/:   flutter test tool/generate_icons_test.dart
// Writes web/favicon.png and web/icons/Icon-*.png. It is a tool, not part of the normal test suite.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lookers/core/theme/app_colors.dart';
import 'package:lookers/core/ui/logo.dart';

/// Where the visible glyphs sit inside the Logo widget's box, as fractions of its size.
class _Bounds {
  const _Bounds(this.left, this.top, this.right, this.bottom);
  final double left, top, right, bottom;
  double get width => right - left;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;
}

/// The cursive L rises above its box and the K runs past its right edge, so the box centre is not
/// the visual centre. Render the logo large on black and scan for lit pixels to find the true bounds.
Future<_Bounds> _measure(WidgetTester tester) async {
  const canvas = 2000.0, origin = 500.0, logo = 1000.0;
  tester.view.physicalSize = const Size(canvas, canvas);
  tester.view.devicePixelRatio = 1;
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: const Color(0xFF000000),
          child: Stack(
            children: [
              Positioned(
                left: origin,
                top: origin,
                child: Logo(
                  size: logo,
                  color: const Color(0xFFFFFFFF),
                  accentColor: const Color(0xFFFFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  late _Bounds bounds;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    var x0 = canvas.toInt(), y0 = canvas.toInt(), x1 = 0, y1 = 0;
    for (var y = 0; y < canvas; y++) {
      for (var x = 0; x < canvas; x++) {
        if (data.getUint8((y * canvas.toInt() + x) * 4) > 60) {
          if (x < x0) x0 = x;
          if (x > x1) x1 = x;
          if (y < y0) y0 = y;
          if (y > y1) y1 = y;
        }
      }
    }
    bounds = _Bounds(
      (x0 - origin) / logo,
      (y0 - origin) / logo,
      (x1 - origin) / logo,
      (y1 - origin) / logo,
    );
  });
  return bounds;
}

/// [fill] is the width of the visible mark as a fraction of the icon. Maskable icons use a smaller
/// fill so the mark stays inside the central safe zone (the OS crops them to a circle or squircle).
Widget _icon(
  double size,
  _Bounds b, {
  required double fill,
  bool transparent = false,
}) {
  final logoSize = size * fill / b.width;
  return SizedBox(
    width: size,
    height: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: transparent
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Palette.light.primaryDeep, Palette.light.primary],
              ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: size / 2 - b.centerX * logoSize,
            top: size / 2 - b.centerY * logoSize,
            child: Logo(
              size: logoSize,
              color: Palette.light.onPrimary,
              accentColor: Palette.dark.accent,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _write(
  WidgetTester tester,
  _Bounds b,
  String path,
  double size, {
  required double fill,
  bool transparent = false,
}) async {
  File(path).parent.createSync(recursive: true);
  tester.view.physicalSize = Size(size, size);
  tester.view.devicePixelRatio = 1;
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: _icon(size, b, fill: fill, transparent: transparent),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File(path).writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

void main() {
  testWidgets('generate icons', (tester) async {
    addTearDown(tester.view.reset);
    final font = FontLoader('Pinyon')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/PinyonScript-Regular.ttf').readAsBytesSync(),
          ),
        ),
      );
    await tester.runAsync(font.load);

    final b = await _measure(tester);

    // ── Web
    await _write(tester, b, 'web/icons/Icon-512.png', 512, fill: 0.76);
    await _write(tester, b, 'web/icons/Icon-192.png', 192, fill: 0.76);
    await _write(tester, b, 'web/icons/Icon-maskable-512.png', 512, fill: 0.6);
    await _write(tester, b, 'web/icons/Icon-maskable-192.png', 192, fill: 0.6);
    // Browser tab favicon: a bolder, larger mark so it stays readable at 32px.
    await _write(tester, b, 'web/favicon.png', 64, fill: 0.86);

    // ── Android: legacy square icons, plus adaptive icon layers (the OS masks the icon to a circle or
    // squircle, so the mark stays inside the central 66dp of the 108dp layer).
    const res = 'android/app/src/main/res';
    const legacy = {
      'mdpi': 48.0,
      'hdpi': 72.0,
      'xhdpi': 96.0,
      'xxhdpi': 144.0,
      'xxxhdpi': 192.0,
    };
    for (final e in legacy.entries) {
      await _write(
        tester,
        b,
        '$res/mipmap-${e.key}/ic_launcher.png',
        e.value,
        fill: 0.66,
      );
    }
    const layer = {
      'mdpi': 108.0,
      'hdpi': 162.0,
      'xhdpi': 216.0,
      'xxhdpi': 324.0,
      'xxxhdpi': 432.0,
    };
    for (final e in layer.entries) {
      await _write(
        tester,
        b,
        '$res/drawable-${e.key}/ic_launcher_foreground.png',
        e.value,
        fill: 0.5,
        transparent: true,
      );
    }
    Directory('$res/mipmap-anydpi-v26').createSync(recursive: true);
    File('$res/mipmap-anydpi-v26/ic_launcher.xml').writeAsStringSync(
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
      '    <background android:drawable="@color/ic_launcher_background"/>\n'
      '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
      '</adaptive-icon>\n',
    );
    final bg = Palette.light.primaryDeep;
    final hex =
        '#${(bg.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    File('$res/values/ic_launcher_background.xml').writeAsStringSync(
      '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">$hex</color>\n</resources>\n',
    );

    // ── iOS launch image (logo on the storyboard's purple background).
    const launch = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
    await _write(
      tester,
      b,
      '$launch/LaunchImage.png',
      168,
      fill: 0.8,
      transparent: true,
    );
    await _write(
      tester,
      b,
      '$launch/LaunchImage@2x.png',
      336,
      fill: 0.8,
      transparent: true,
    );
    await _write(
      tester,
      b,
      '$launch/LaunchImage@3x.png',
      504,
      fill: 0.8,
      transparent: true,
    );

    // ── iOS: every size listed in the icon set. Apple rejects icons with an alpha channel, so the
    // PNGs are flattened afterwards (see docs: `sips` round trip).
    const iosSet = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final contents =
        jsonDecode(File('$iosSet/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
    final done = <String>{};
    for (final image
        in (contents['images'] as List).cast<Map<String, dynamic>>()) {
      final name = image['filename'] as String?;
      if (name == null || !done.add(name)) continue;
      final points = double.parse((image['size'] as String).split('x').first);
      final scale = double.parse(
        (image['scale'] as String).replaceAll('x', ''),
      );
      await _write(tester, b, '$iosSet/$name', points * scale, fill: 0.7);
    }
  });
}
