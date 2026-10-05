// Oyunun kısa efekt seslerini sinüs/kare dalgadan üretir.
// Kullanım: dart run tool/generate_sounds.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 44100;
const volume = 0.3; // düşük ses seviyesi

typedef Wave = double Function(double phase);

double sine(double p) => sin(2 * pi * p);
double square(double p) => (p % 1) < 0.5 ? 1 : -1;

/// Frekansı `f0`'dan `f1`'e kayan ton; faz birikimli (tıkırtısız).
List<double> tone(
  double ms,
  double f0, [
  double? f1,
  Wave wave = sine,
  double gain = 1,
]) {
  final n = (sampleRate * ms / 1000).round();
  final out = List<double>.filled(n, 0);
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / n;
    final f = f0 + ((f1 ?? f0) - f0) * t;
    phase += f / sampleRate;
    out[i] = wave(phase) * gain * envelope(i, n);
  }
  return out;
}

/// Kısa atak, üstel sönüm; uçlarda tıkırtı olmaz.
double envelope(int i, int n) {
  final attack = min(n ~/ 10, (sampleRate * 0.004).round());
  final a = attack == 0 ? 1.0 : min(1.0, i / attack);
  final release = min(1.0, (n - i) / (sampleRate * 0.006));
  final decay = exp(-3.0 * i / n);
  return a * release * decay;
}

List<double> concat(List<List<double>> parts) => [for (final p in parts) ...p];

List<double> mix(List<double> a, List<double> b) => [
  for (var i = 0; i < max(a.length, b.length); i++)
    (i < a.length ? a[i] : 0) + (i < b.length ? b[i] : 0),
];

List<double> noise(double ms, double gain) {
  final rnd = Random(42);
  final n = (sampleRate * ms / 1000).round();
  return [
    for (var i = 0; i < n; i++)
      (rnd.nextDouble() * 2 - 1) * gain * envelope(i, n),
  ];
}

Uint8List wav(List<double> samples) {
  final data = ByteData(44 + samples.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little); // PCM chunk boyutu
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  data.setUint16(32, 2, Endian.little); // block align
  data.setUint16(34, 16, Endian.little); // 16 bit
  str(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i] * volume).clamp(-1.0, 1.0);
    data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

double triangle(double p) => 4 * ((p % 1) - 0.5).abs() - 1;

/// "Robot uyanıyor" açılış sesi (~1.4 sn): alçak bir açılma vınlaması,
/// ardından birbirine hafif binen dört notalı parlak arpej (C5 E5 G5 C6) ve
/// son notada hafif yankı. Tepe değeri diğer efektlerden biraz düşüktür;
/// başı ve sonu tıkırtısız yumuşar.
List<double> splash() {
  const total = 1.4;
  final n = (sampleRate * total).round();
  final out = List<double>.filled(n, 0);

  double smooth(double x) {
    final t = x.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  // 0–250 ms: 180 → 440 Hz yükselen sinüs, yumuşak giriş ve çıkış.
  var phase = 0.0;
  final whooshN = (sampleRate * 0.25).round();
  for (var i = 0; i < whooshN; i++) {
    final t = i / whooshN;
    phase += (180 + (440 - 180) * t * t) / sampleRate;
    final env = smooth(t / 0.3) * smooth((1 - t) / 0.35);
    out[i] += sine(phase) * 0.55 * env;
  }

  // Arpej: her nota ~150 ms aralıkla; ADSR zarfı notaların binmesini sağlar.
  const notes = [523.25, 659.25, 783.99, 1046.50];
  for (var k = 0; k < notes.length; k++) {
    final last = k == notes.length - 1;
    final start = (sampleRate * (0.25 + 0.15 * k)).round();
    final hold = sampleRate * 0.15;
    final release = sampleRate * (last ? 0.45 : 0.22);
    var p = 0.0;
    for (var i = 0; start + i < n && i < hold + release; i++) {
      final a = sampleRate * 0.012, d = sampleRate * 0.06;
      final env = i < a
          ? i / a
          : i < a + d
          ? 1 - 0.4 * (i - a) / d
          : i < hold
          ? 0.6
          : 0.6 * exp(-4 * (i - hold) / release);
      p += notes[k] / sampleRate;
      out[start + i] += (0.8 * sine(p) + 0.2 * triangle(p)) * 0.5 * env;
    }
  }

  // Son notanın üzerinde ~300 ms hafif yankı.
  final echoFrom = (sampleRate * 0.70).round();
  for (final (delay, gain) in [(0.11, 0.32), (0.22, 0.14)]) {
    final dn = (sampleRate * delay).round();
    for (var i = n - 1; i >= echoFrom + dn; i--) {
      out[i] += out[i - dn] * gain;
    }
  }

  // Normalleştir (tepe 0.85 × genel ses seviyesi) ve uçları yumuşat.
  final peak = out.fold(0.0, (m, v) => max(m, v.abs()));
  for (var i = 0; i < n; i++) {
    final edge = min(
      1.0,
      min(i / (sampleRate * 0.005), (n - i) / (sampleRate * 0.03)),
    );
    out[i] = out[i] / peak * 0.85 * edge;
  }
  return out;
}

void main() {
  const c5 = 523.25, e5 = 659.25, g5 = 783.99;
  const c6 = 1046.50, e6 = 1318.51;

  final sounds = <String, List<double>>{
    'tap': tone(40, 880),
    'card_add': tone(80, 660, 990),
    'card_remove': tone(80, 660, 440),
    'step': tone(50, 520),
    'turn': tone(60, 700),
    'battery': concat([tone(60, c6), tone(60, e6)]),
    'crash': mix(tone(200, 300, 80, square, 0.5), noise(200, 0.5)),
    'win': concat([tone(150, c5), tone(150, e5), tone(300, g5)]),
    'star': mix(tone(100, 1568), tone(100, 3136, null, sine, 0.3)),
    // Profesyonel bir sesle değiştirmek için assets/sounds/splash.wav
    // dosyasını değiştirmek yeterli; kod bu sabit adı kullanır.
    'splash': splash(),
  };

  final dir = Directory('assets/sounds')..createSync(recursive: true);
  for (final entry in sounds.entries) {
    File('${dir.path}/${entry.key}.wav').writeAsBytesSync(wav(entry.value));
    stdout.writeln('${entry.key}.wav');
  }
}
