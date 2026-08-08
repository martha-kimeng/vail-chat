// Vail App Icon Generator
// Produces a 1024×1024 PNG of the Vail logo, then resizes it to every
// required iOS and Android size.
//
// Run from the project root:
//   dart run tools/icon_gen/bin/generate.dart

import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

// ── Palette ──────────────────────────────────────────────────────────────────
// Hero gradient: ink (#1A1A2E) → deep purple (#2D1B3D) → dark rose (#4A1942)
// Brand rose:    #E8516A   roseDark: #C43150
// White:         #FFFFFF

const int kInk       = 0xFF1A1A2E;
const int kPurple    = 0xFF2D1B3D;
const int kDarkRose  = 0xFF4A1942;
const int kRose      = 0xFFE8516A;
const int kRoseDark  = 0xFFC43150;
const int kWhite     = 0xFFFFFFFF;

// ARGB → img.ColorRgba8
img.Color argb(int v) => img.ColorRgba8(
  (v >> 16) & 0xFF,
  (v >> 8)  & 0xFF,
   v        & 0xFF,
  (v >> 24) & 0xFF,
);

img.Color argbA(int rgb, int alpha) => img.ColorRgba8(
  (rgb >> 16) & 0xFF,
  (rgb >> 8)  & 0xFF,
   rgb        & 0xFF,
  alpha,
);

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Lerp between two ARGB ints by t ∈ [0,1]
img.Color lerpColor(int a, int b, double t) {
  int lerp(int ca, int cb) => (ca + (cb - ca) * t).round().clamp(0, 255);
  return img.ColorRgba8(
    lerp((a >> 16) & 0xFF, (b >> 16) & 0xFF),
    lerp((a >> 8)  & 0xFF, (b >> 8)  & 0xFF),
    lerp( a        & 0xFF,  b        & 0xFF),
    lerp((a >> 24) & 0xFF, (b >> 24) & 0xFF),
  );
}

/// 3-stop radial gradient colour at radius ratio r ∈ [0,1]
img.Color heroGradient(double r) {
  // centre = kDarkRose, mid = kPurple, edge = kInk
  if (r < 0.45) {
    return lerpColor(kDarkRose, kPurple, r / 0.45);
  } else {
    return lerpColor(kPurple, kInk, (r - 0.45) / 0.55);
  }
}

/// Alpha-blend src (with alpha) over a base img.Color
img.Color blendOver(img.Color base, img.Color src) {
  final double a = src.a / 255.0;
  final double ia = 1.0 - a;
  return img.ColorRgba8(
    (src.r * a + base.r * ia).round().clamp(0, 255),
    (src.g * a + base.g * ia).round().clamp(0, 255),
    (src.b * a + base.b * ia).round().clamp(0, 255),
    255,
  );
}

// ── Geometry helpers ─────────────────────────────────────────────────────────

/// Point-in-rounded-rectangle test
bool inRoundRect(
    double px, double py, double l, double t, double r, double b, double rx) {
  if (px < l || px > r || py < t || py > b) return false;
  // corners
  if (px < l + rx && py < t + rx) {
    return _dist(px, py, l + rx, t + rx) <= rx;
  }
  if (px > r - rx && py < t + rx) {
    return _dist(px, py, r - rx, t + rx) <= rx;
  }
  if (px < l + rx && py > b - rx) {
    return _dist(px, py, l + rx, b - rx) <= rx;
  }
  if (px > r - rx && py > b - rx) {
    return _dist(px, py, r - rx, b - rx) <= rx;
  }
  return true;
}

double _dist(double ax, double ay, double bx, double by) {
  final dx = ax - bx, dy = ay - by;
  return math.sqrt(dx * dx + dy * dy);
}

/// Signed distance from point to a cubic Bézier (used for anti-aliased tail).
/// We approximate by sampling the curve.
double distToCubic(
    double px, double py,
    double x0, double y0,
    double cx1, double cy1,
    double cx2, double cy2,
    double x1, double y1) {
  double minD2 = double.infinity;
  for (int i = 0; i <= 40; i++) {
    final double t = i / 40.0;
    final double it = 1 - t;
    final double bx = it*it*it*x0 + 3*it*it*t*cx1 + 3*it*t*t*cx2 + t*t*t*x1;
    final double by = it*it*it*y0 + 3*it*it*t*cy1 + 3*it*t*t*cy2 + t*t*t*y1;
    final double d2 = (px-bx)*(px-bx) + (py-by)*(py-by);
    if (d2 < minD2) minD2 = d2;
  }
  return math.sqrt(minD2);
}

// ── Point-in-polygon (ray casting) for the flame tail ─────────────────────────
bool pointInPolygon(double px, double py, List<List<double>> poly) {
  int n = poly.length;
  bool inside = false;
  for (int i = 0, j = n - 1; i < n; j = i++) {
    final xi = poly[i][0], yi = poly[i][1];
    final xj = poly[j][0], yj = poly[j][1];
    if (((yi > py) != (yj > py)) &&
        (px < (xj - xi) * (py - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
  }
  return inside;
}

/// Approximate the tail Bézier curves as polygon points
List<List<double>> buildTailPolygon(double s) {
  final double cx = s / 2, cy = s / 2;
  final double bubbleW = s * 0.56;
  final double bubbleH = s * 0.44;
  final double bubbleL = cx - bubbleW / 2;
  final double bubbleT = cy - bubbleH / 2 - s * 0.04;
  final double bubbleBot = bubbleT + bubbleH;
  final double radius = s * 0.072;
  final double tailStartX = cx - s * 0.04;
  final double tailTipX = cx - s * 0.18;
  final double tailTipY = bubbleBot + s * 0.155;

  final List<List<double>> pts = [];

  // outer curve: tailStartX,bubbleBot → tip (cubic)
  for (int i = 0; i <= 20; i++) {
    final double t = i / 20.0;
    final double it = 1 - t;
    final cx1 = tailStartX - s * 0.01, cy1 = bubbleBot + s * 0.06;
    final cx2 = tailTipX + s * 0.03,   cy2 = tailTipY - s * 0.02;
    final bx = it*it*it*tailStartX + 3*it*it*t*cx1 + 3*it*t*t*cx2 + t*t*t*tailTipX;
    final by = it*it*it*bubbleBot   + 3*it*it*t*cy1 + 3*it*t*t*cy2 + t*t*t*tailTipY;
    pts.add([bx, by]);
  }
  // inner curve: tip → bubbleL+radius, bubbleBot
  for (int i = 0; i <= 20; i++) {
    final double t = i / 20.0;
    final double it = 1 - t;
    final cx1 = tailTipX - s * 0.02, cy1 = tailTipY - s * 0.04;
    final cx2 = bubbleL + radius,      cy2 = bubbleBot + s * 0.01;
    final bx = it*it*it*tailTipX + 3*it*it*t*cx1 + 3*it*t*t*cx2 + t*t*t*(bubbleL+radius);
    final by = it*it*it*tailTipY + 3*it*it*t*cy1 + 3*it*t*t*cy2 + t*t*t*bubbleBot;
    pts.add([bx, by]);
  }

  return pts;
}

// ── Main painting ─────────────────────────────────────────────────────────────

img.Image paintIcon(int size) {
  final image = img.Image(width: size, height: size);
  final double s = size.toDouble();
  final double cx = s / 2, cy = s / 2;

  // Bubble geometry (mirrored from generator script)
  final double bubbleW = s * 0.56;
  final double bubbleH = s * 0.44;
  final double bubbleL = cx - bubbleW / 2;
  final double bubbleT = cy - bubbleH / 2 - s * 0.04;
  final double bubbleR = cx + bubbleW / 2;
  final double bubbleBot = bubbleT + bubbleH;
  final double radius = s * 0.072;

  final tailPoly = buildTailPolygon(s);

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final double px = x + 0.5, py = y + 0.5;

      // ── 1. Hero radial gradient background ──────────────────────────────
      final double dx = px - cx, dy = py - cy * 0.85;
      final double r = math.sqrt(dx * dx + dy * dy) / (s * 0.72);
      img.Color c = heroGradient(r.clamp(0.0, 1.0));

      // ── 2. Vignette ──────────────────────────────────────────────────────
      final double vd = math.sqrt((px-cx)*(px-cx) + (py-cy)*(py-cy)) / (s*0.56);
      if (vd > 1.0) {
        final double vt = ((vd - 1.0) / 0.8).clamp(0.0, 1.0);
        final int va = (vt * 0x55).round();
        c = blendOver(c, img.ColorRgba8(0, 0, 0, va));
      }

      // ── 3. Glow ring ─────────────────────────────────────────────────────
      final double ringD = _dist(px, py, cx, cy);
      final double ringTarget = s * 0.36;
      final double ringDist = (ringD - ringTarget).abs();
      if (ringDist < s * 0.04) {
        final double ringT = 1.0 - (ringDist / (s * 0.04));
        final int ringA = (ringT * ringT * 0x44).round();
        c = blendOver(c, img.ColorRgba8(0xE8, 0x51, 0x6A, ringA));
      }

      // ── 4. Speech bubble body ─────────────────────────────────────────────
      final bool inBubble = inRoundRect(px, py, bubbleL, bubbleT, bubbleR, bubbleBot, radius);
      final bool inTail   = pointInPolygon(px, py, tailPoly);

      if (inBubble || inTail) {
        // Linear gradient: rose → roseDark (top to bottom)
        final double gradT = ((py - bubbleT) / (bubbleBot + s * 0.16 - bubbleT)).clamp(0.0, 1.0);
        final img.Color fill = lerpColor(kRose, kRoseDark, gradT);

        // Soft highlight: upper-left radial gleam
        final double hlDx = px - (bubbleL + bubbleW * 0.3);
        final double hlDy = py - (bubbleT + bubbleH * 0.25);
        final double hlD  = math.sqrt(hlDx*hlDx + hlDy*hlDy) / (bubbleW * 0.45);
        int hlA = 0;
        if (hlD < 1.0) {
          hlA = ((1.0 - hlD) * (1.0 - hlD) * 0x44).round();
        }

        img.Color bubbleColor = blendOver(c, fill);
        if (hlA > 0) {
          bubbleColor = blendOver(bubbleColor, img.ColorRgba8(255, 255, 255, hlA));
        }
        c = bubbleColor;
      }

      // ── 5. Anti-aliased bubble border (soft edge) ─────────────────────────
      // We achieve AA by blending near the bubble edges using distance fields.
      // Only needed at the rounded-rect boundary:
      if (!inBubble && !inTail) {
        // Distance to nearest bubble edge (approximate via clamped rectangle)
        final double nx = px.clamp(bubbleL + radius, bubbleR - radius);
        final double ny = py.clamp(bubbleT + radius, bubbleBot - radius);
        // nearest point on straight section
        double edgeDist = _dist(px, py, nx, ny);
        // corners
        if (px < bubbleL + radius && py < bubbleT + radius) {
          edgeDist = (_dist(px, py, bubbleL+radius, bubbleT+radius) - radius).abs();
        } else if (px > bubbleR - radius && py < bubbleT + radius) {
          edgeDist = (_dist(px, py, bubbleR-radius, bubbleT+radius) - radius).abs();
        } else if (px < bubbleL + radius && py > bubbleBot - radius) {
          edgeDist = (_dist(px, py, bubbleL+radius, bubbleBot-radius) - radius).abs();
        } else if (px > bubbleR - radius && py > bubbleBot - radius) {
          edgeDist = (_dist(px, py, bubbleR-radius, bubbleBot-radius) - radius).abs();
        }
        if (edgeDist < 1.5 && py < bubbleBot) {
          final double t = (1.5 - edgeDist) / 1.5;
          final double gradT = ((py - bubbleT) / (bubbleBot - bubbleT)).clamp(0.0, 1.0);
          final img.Color fill = lerpColor(kRose, kRoseDark, gradT);
          c = blendOver(c, img.ColorRgba8(fill.r.round(), fill.g.round(), fill.b.round(), (t * 255).round()));
        }
      }

      // ── 5. Outer bubble glow ──────────────────────────────────────────────
      if (!inBubble && !inTail) {
        // Soft halo around the bubble
        final double bx = px.clamp(bubbleL, bubbleR);
        final double by = py.clamp(bubbleT, bubbleBot);
        final double glowD = _dist(px, py, bx, by);
        if (glowD < s * 0.06) {
          final double gt = 1.0 - (glowD / (s * 0.06));
          final int ga = (gt * gt * 0x33).round();
          c = blendOver(c, img.ColorRgba8(0xE8, 0x51, 0x6A, ga));
        }
      }

      // ── 6. Three dots (ellipsis) ──────────────────────────────────────────
      final double dotY = bubbleT + bubbleH * 0.52;
      final double dotR = s * 0.034;
      final double dotSpacing = s * 0.098;

      for (final double dotX in [cx - dotSpacing, cx, cx + dotSpacing]) {
        final double dd = _dist(px, py, dotX, dotY);
        if (dd <= dotR + 1.0) {
          final int dotA = dd <= dotR
              ? 255
              : ((1.0 - (dd - dotR)).clamp(0.0, 1.0) * 255).round();
          c = blendOver(c, img.ColorRgba8(255, 255, 255, dotA));
        }
      }

      image.setPixel(x, y, c);
    }
  }

  return image;
}

// ── Icon size tables ──────────────────────────────────────────────────────────

const List<Map<String, dynamic>> kIosSizes = [
  {'file': 'Icon-App-20x20@1x.png',     'px': 20},
  {'file': 'Icon-App-20x20@2x.png',     'px': 40},
  {'file': 'Icon-App-20x20@3x.png',     'px': 60},
  {'file': 'Icon-App-29x29@1x.png',     'px': 29},
  {'file': 'Icon-App-29x29@2x.png',     'px': 58},
  {'file': 'Icon-App-29x29@3x.png',     'px': 87},
  {'file': 'Icon-App-40x40@1x.png',     'px': 40},
  {'file': 'Icon-App-40x40@2x.png',     'px': 80},
  {'file': 'Icon-App-40x40@3x.png',     'px': 120},
  {'file': 'Icon-App-60x60@2x.png',     'px': 120},
  {'file': 'Icon-App-60x60@3x.png',     'px': 180},
  {'file': 'Icon-App-76x76@1x.png',     'px': 76},
  {'file': 'Icon-App-76x76@2x.png',     'px': 152},
  {'file': 'Icon-App-83.5x83.5@2x.png', 'px': 167},
  {'file': 'Icon-App-1024x1024@1x.png', 'px': 1024},
];

const List<Map<String, dynamic>> kAndroidSizes = [
  {'dir': 'mipmap-mdpi',    'px': 48},
  {'dir': 'mipmap-hdpi',    'px': 72},
  {'dir': 'mipmap-xhdpi',   'px': 96},
  {'dir': 'mipmap-xxhdpi',  'px': 144},
  {'dir': 'mipmap-xxxhdpi', 'px': 192},
];

// ── Entry point ───────────────────────────────────────────────────────────────

Future<void> main() async {
  // Resolve the project root (two directories up from tools/icon_gen/bin/)
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final projectRoot = scriptDir.parent.parent.parent.path;

  print('▸ Project root: $projectRoot');
  print('▸ Rendering master icon at 1024×1024…');

  final master = paintIcon(1024);

  // Save master to assets/images/
  final assetsDir = Directory('$projectRoot/assets/images');
  assetsDir.createSync(recursive: true);
  final masterFile = File('${assetsDir.path}/app_icon_1024.png');
  masterFile.writeAsBytesSync(img.encodePng(master));
  print('  ✓ Saved ${masterFile.path}');

  // ── iOS ──────────────────────────────────────────────────────────────────
  print('▸ Deploying iOS icons…');
  final iosDir = '$projectRoot/ios/Runner/Assets.xcassets/AppIcon.appiconset';

  for (final entry in kIosSizes) {
    final int px = entry['px'] as int;
    final String filename = entry['file'] as String;
    final resized = img.copyResize(master, width: px, height: px,
        interpolation: img.Interpolation.cubic);
    final outFile = File('$iosDir/$filename');
    outFile.writeAsBytesSync(img.encodePng(resized));
    print('  ✓ ${outFile.path} (${px}px)');
  }

  // ── Android ───────────────────────────────────────────────────────────────
  print('▸ Deploying Android icons…');
  final androidRes = '$projectRoot/android/app/src/main/res';

  for (final entry in kAndroidSizes) {
    final int px = entry['px'] as int;
    final String dirName = entry['dir'] as String;
    final resized = img.copyResize(master, width: px, height: px,
        interpolation: img.Interpolation.cubic);
    final outFile = File('$androidRes/$dirName/ic_launcher.png');
    outFile.writeAsBytesSync(img.encodePng(resized));

    // Also write the round variant (same source, OS applies the mask)
    final roundFile = File('$androidRes/$dirName/ic_launcher_round.png');
    roundFile.writeAsBytesSync(img.encodePng(resized));
    print('  ✓ $dirName (${px}px)');
  }

  print('');
  print('✓ All icons generated and deployed.');
}
