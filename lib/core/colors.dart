import 'package:flutter/material.dart';

/// Uygulamanın tüm renkleri. Düz (flat) tasarım: gölge ve gradyan yok.
abstract final class AppColors {
  static const background = Color(0xFF26215C);
  static const panel = Color(0xFF3C3489);
  static const floor = Color(0xFF534AB7);
  static const wall = Color(0xFF26215C);
  static const textSecondary = Color(0xFFCECBF6);
  static const textPrimary = Color(0xFFEEEDFE);

  static const robotBody = Color(0xFF5DCAA5);
  static const robotDetail = Color(0xFF04342C);

  static const goalOuter = Color(0xFFFAC775);
  static const goalInner = Color(0xFFEF9F27);

  static const batteryBody = Color(0xFFFAC775);
  static const batteryTip = Color(0xFF633806);

  static const forwardCard = Color(0xFF1D9E75);
  static const forwardIcon = Color(0xFFE1F5EE);
  static const turnCard = Color(0xFFD85A30);
  static const turnIcon = Color(0xFFFAECE7);

  static const primaryButton = Color(0xFF5DCAA5);
  static const primaryButtonText = Color(0xFF04342C);
  static const secondaryButton = Color(0xFF534AB7);
  static const secondaryButtonText = Color(0xFFEEEDFE);

  static const activeHighlight = Color(0xFFFAC775);
  static const starEarned = Color(0xFFFAC775);
  static const starEmpty = Color(0xFF534AB7);

  // 5–7 yaş mutlak yön kartları: okumadan ayırt edilebilen dört ton.
  static const upCard = Color(0xFF1D9E75);
  static const downCard = Color(0xFF378ADD);
  static const leftCard = Color(0xFFD85A30);
  static const rightCard = Color(0xFF7F77DD);
  static const upIcon = Color(0xFFE1F5EE);
  static const downIcon = Color(0xFFE6F1FB);
  static const leftIcon = Color(0xFFFAECE7);
  static const rightIcon = Color(0xFFEEEDFE);

  // 13+ özel kareler.
  static const ice = Color(0xFFB5D4F4);
  static const door = Color(0xFF854F0B);
  static const key = Color(0xFFFAC775);
  static const portalOuter = Color(0xFF7F77DD);
  static const portalInner = Color(0xFFD4537E);

  // Dünya 2 döngü kartları (Tekrarla). Mor 5–7'nin Sağ kartı, sarı etkin
  // kart vurgusu olduğu için pembe.
  static const loopCard = Color(0xFFD4537E);
  static const loopIcon = Color(0xFFFBEAF0);

  /// Seçili karakter çerçevesi.
  static const selected = Color(0xFF5DCAA5);

  /// Şerit dolu uyarısı için kırmızımsı ton.
  static const warning = Color(0xFFE24B4A);
}
