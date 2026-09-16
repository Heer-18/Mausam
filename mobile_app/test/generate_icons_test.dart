import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate high resolution distinct weather icons for dynamic aliases', () async {
    final densities = {
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };

    for (final entry in densities.entries) {
      final folder = entry.key;
      final size = entry.value.toDouble();

      await _renderAndSaveIcon(
        folder: folder,
        filename: 'ic_launcher_sunny.png',
        size: size,
        painter: SunnyIconPainter(),
      );

      await _renderAndSaveIcon(
        folder: folder,
        filename: 'ic_launcher_rainy.png',
        size: size,
        painter: RainyIconPainter(),
      );

      await _renderAndSaveIcon(
        folder: folder,
        filename: 'ic_launcher_night.png',
        size: size,
        painter: NightIconPainter(),
      );

      await _renderAndSaveIcon(
        folder: folder,
        filename: 'ic_launcher_cloudy.png',
        size: size,
        painter: CloudyIconPainter(),
      );
    }
  });
}

Future<void> _renderAndSaveIcon({
  required String folder,
  required String filename,
  required double size,
  required CustomPainter painter,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

  painter.paint(canvas, Size(size, size));

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  final outPath = 'android/app/src/main/res/$folder/$filename';
  final file = File(outPath);
  await file.create(recursive: true);
  await file.writeAsBytes(bytes);
}

// ---------------------------------------------------------------------------
// 1. SUNNY LAUNCHER ICON
// ---------------------------------------------------------------------------
class SunnyIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final r = w / 2;
    final center = Offset(r, r);

    // Rounded background squircle / circle with sunny cyan-blue gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0284C7), Color(0xFF0369A1), Color(0xFF075985)],
      ).createShader(Rect.fromLTWH(0, 0, w, w));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, w), Radius.circular(w * 0.22)), bgPaint);

    // Radiant Sun Flare
    final flarePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFDE047).withOpacity(0.4),
          const Color(0xFFF59E0B).withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.85));
    canvas.drawCircle(center, r * 0.85, flarePaint);

    // Solar Rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFDE047).withOpacity(0.85)
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = i * (math.pi / 4);
      final p1 = Offset(center.dx + math.cos(angle) * (r * 0.52), center.dy + math.sin(angle) * (r * 0.52));
      final p2 = Offset(center.dx + math.cos(angle) * (r * 0.72), center.dy + math.sin(angle) * (r * 0.72));
      canvas.drawLine(p1, p2, rayPaint);
    }

    // Glowing Golden Sun Core
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.2),
        colors: [
          Color(0xFFFFFBEB),
          Color(0xFFFEF08A),
          Color(0xFFF59E0B),
          Color(0xFFD97706),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.42));
    canvas.drawCircle(center, r * 0.40, sunPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 2. RAINY LAUNCHER ICON
// ---------------------------------------------------------------------------
class RainyIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // Rainy dark slate-navy background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)],
      ).createShader(Rect.fromLTWH(0, 0, w, w));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, w), Radius.circular(w * 0.22)), bgPaint);

    // Rain Cloud
    final cloudPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF94A3B8), Color(0xFF64748B), Color(0xFF334155)],
      ).createShader(Rect.fromLTWH(w * 0.15, w * 0.2, w * 0.7, w * 0.45));

    final cloudPath = Path();
    cloudPath.addOval(Rect.fromCircle(center: Offset(w * 0.42, w * 0.38), radius: w * 0.20));
    cloudPath.addOval(Rect.fromCircle(center: Offset(w * 0.62, w * 0.42), radius: w * 0.16));
    cloudPath.addOval(Rect.fromCircle(center: Offset(w * 0.28, w * 0.46), radius: w * 0.14));
    cloudPath.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.20, w * 0.42, w * 0.60, w * 0.18), Radius.circular(w * 0.1)));
    canvas.drawPath(cloudPath, cloudPaint);

    // Neon Cyan Raindrops
    final dropPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(Rect.fromLTWH(0, 0, w, w))
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;

    final drops = [
      Offset(w * 0.32, w * 0.66),
      Offset(w * 0.50, w * 0.70),
      Offset(w * 0.68, w * 0.66),
      Offset(w * 0.40, w * 0.82),
      Offset(w * 0.58, w * 0.82),
    ];

    for (final d in drops) {
      canvas.drawLine(d, Offset(d.dx - w * 0.04, d.dy + w * 0.08), dropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 3. NIGHT LAUNCHER ICON (CRESCENT MOON & STARS)
// ---------------------------------------------------------------------------
class NightIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // Deep Midnight Cosmic Sky
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF030712), Color(0xFF0B132B), Color(0xFF1E1B4B)],
      ).createShader(Rect.fromLTWH(0, 0, w, w));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, w), Radius.circular(w * 0.22)), bgPaint);

    // Twinkling Stars
    final starPaint = Paint()..color = Colors.white.withOpacity(0.9);
    final starGlow = Paint()
      ..color = const Color(0xFFBAE6FD).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final stars = [
      Offset(w * 0.22, w * 0.25),
      Offset(w * 0.78, w * 0.22),
      Offset(w * 0.82, w * 0.68),
      Offset(w * 0.25, w * 0.72),
      Offset(w * 0.40, w * 0.82),
      Offset(w * 0.70, w * 0.45),
    ];

    for (final s in stars) {
      canvas.drawCircle(s, w * 0.02, starGlow);
      canvas.drawCircle(s, w * 0.012, starPaint);
    }

    // Glowing Realistic Crescent Moon
    final moonCenter = Offset(w * 0.48, w * 0.48);
    final mr = w * 0.26;

    final moonGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFBAE6FD).withOpacity(0.4),
          const Color(0xFF93C5FD).withOpacity(0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: moonCenter, radius: mr * 1.8));
    canvas.drawCircle(moonCenter, mr * 1.6, moonGlow);

    // Pure Crescent Shape
    canvas.save();
    canvas.translate(moonCenter.dx, moonCenter.dy);
    canvas.rotate(-math.pi / 5.0);

    final moonPath = Path();
    moonPath.moveTo(0, -mr);
    moonPath.arcToPoint(Offset(0, mr), radius: Radius.circular(mr), clockwise: true);
    moonPath.arcToPoint(Offset(0, -mr), radius: Radius.elliptical(mr * 0.45, mr), clockwise: false);

    final moonPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.4, -0.2),
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF1F5F9),
          Color(0xFFE2E8F0),
          Color(0xFF94A3B8),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: mr));

    canvas.drawPath(moonPath, moonPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 4. CLOUDY LAUNCHER ICON
// ---------------------------------------------------------------------------
class CloudyIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // Crisp Cerulean Cloudy Sky
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0369A1)],
      ).createShader(Rect.fromLTWH(0, 0, w, w));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, w), Radius.circular(w * 0.22)), bgPaint);

    // Back Cloud
    final backCloudPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
      ).createShader(Rect.fromLTWH(w * 0.3, w * 0.2, w * 0.5, w * 0.4));

    final backPath = Path();
    backPath.addOval(Rect.fromCircle(center: Offset(w * 0.58, w * 0.38), radius: w * 0.18));
    backPath.addOval(Rect.fromCircle(center: Offset(w * 0.72, w * 0.45), radius: w * 0.14));
    canvas.drawPath(backPath, backCloudPaint);

    // Front Pure 3D White Cloud
    final frontCloudPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
      ).createShader(Rect.fromLTWH(w * 0.15, w * 0.35, w * 0.7, w * 0.45));

    final frontPath = Path();
    frontPath.addOval(Rect.fromCircle(center: Offset(w * 0.42, w * 0.50), radius: w * 0.22));
    frontPath.addOval(Rect.fromCircle(center: Offset(w * 0.65, w * 0.54), radius: w * 0.18));
    frontPath.addOval(Rect.fromCircle(center: Offset(w * 0.26, w * 0.56), radius: w * 0.15));
    frontPath.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, w * 0.54, w * 0.64, w * 0.22), Radius.circular(w * 0.11)));
    canvas.drawPath(frontPath, frontCloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
