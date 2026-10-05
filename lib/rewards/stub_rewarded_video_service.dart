import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../l10n/l10n.dart';
import 'rewarded_video_service.dart';

/// Geçici sahte video: koyu tam ekran, 5 sn geri sayım. Gerçek reklam
/// SDK'sı entegre edilene kadar yalnızca debug derlemesinde kullanılabilir;
/// mağaza sürümünde Video jokeri görünmez.
class StubRewardedVideoService implements RewardedVideoService {
  StubRewardedVideoService({
    bool? available,
    this.duration = const Duration(seconds: 5),
  }) : _available = available ?? kDebugMode;

  final bool _available;
  final Duration duration;

  @override
  bool get isAvailable => _available;

  @override
  Future<void> preload() async {}

  @override
  Future<RewardedVideoResult> show(BuildContext context) async {
    if (!_available) return RewardedVideoResult.failed;
    final result = await Navigator.of(context).push<RewardedVideoResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _StubVideoPage(duration: duration),
      ),
    );
    return result ?? RewardedVideoResult.dismissed;
  }
}

class _StubVideoPage extends StatefulWidget {
  const _StubVideoPage({required this.duration});

  final Duration duration;

  @override
  State<_StubVideoPage> createState() => _StubVideoPageState();
}

class _StubVideoPageState extends State<_StubVideoPage> {
  late int _left = widget.duration.inSeconds;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) {
        _timer.cancel();
        Navigator.pop(context, RewardedVideoResult.completed);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, RewardedVideoResult.dismissed);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.ondemand_video,
                      color: AppColors.textSecondary,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.videoPlaceholder,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_left.clamp(0, 99)}',
                      style: const TextStyle(
                        color: AppColors.activeHighlight,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pop(context, RewardedVideoResult.dismissed),
                  child: Text(
                    l.close,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
