// Logodan ikon ve açılış görsellerini üretir.
// Kullanım: dart run tool/make_icon_foreground.dart
//
// Çıktılar (assets/images/):
// - algobot_icon_foreground.png: 1024×1024 şeffaf tuval, logo ortada ve
//   tuvalin ~%66'sını kaplar (Android uyarlanabilir ikon ve Android 12
//   açılış ikonu kenarları kırptığı için güvenli alan).
// - algobot_icon.png: kare, #26215C zeminli ikon kaynağı. Logo kare
//   olmadığı (1536×1024) için kesilmez; üst ve alta zemin rengi eklenir.
// - algobot_splash.png: yerel açılış logosu. 864 px = 216 dp (@4x); Flutter
//   açılış ekranı logoyu 240 dp'nin %90'ından başlatır, geçiş kesintisizdir.
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const background = (0x26, 0x21, 0x5C);

img.Image _fit(img.Image src, int maxW, int maxH) {
  final scale = min(maxW / src.width, maxH / src.height);
  return img.copyResize(
    src,
    width: (src.width * scale).round(),
    height: (src.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );
}

img.Image _canvas(int size, {bool opaque = false}) {
  final c = img.Image(width: size, height: size, numChannels: 4);
  final (r, g, b) = background;
  img.fill(c, color: img.ColorRgba8(r, g, b, opaque ? 255 : 0));
  return c;
}

img.Image _centered(img.Image canvas, img.Image logo) => img.compositeImage(
  canvas,
  logo,
  dstX: (canvas.width - logo.width) ~/ 2,
  dstY: (canvas.height - logo.height) ~/ 2,
);

void main() {
  final logo = img.decodePng(
    File('assets/images/algobot_logo.png').readAsBytesSync(),
  )!;
  stdout.writeln(
    'Logo: ${logo.width}×${logo.height}, '
    'kanal: ${logo.numChannels}',
  );

  const size = 1024;
  final safe = (size * 0.66).round();
  final foreground = _centered(_canvas(size), _fit(logo, safe, safe));
  File(
    'assets/images/algobot_icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(foreground));

  final icon = _centered(_canvas(size, opaque: true), _fit(logo, size, size));
  File('assets/images/algobot_icon.png').writeAsBytesSync(img.encodePng(icon));

  final splash = _fit(logo, 864, 864);
  File(
    'assets/images/algobot_splash.png',
  ).writeAsBytesSync(img.encodePng(splash));

  stdout.writeln(
    'Üretildi: algobot_icon_foreground.png ($size), '
    'algobot_icon.png ($size), algobot_splash.png '
    '(${splash.width}×${splash.height})',
  );
}
