import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import '../../models/age_group.dart';
import '../../data/session_repository.dart';
import '../../review/review_service.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import 'app_button.dart';

/// Ebeveyn kapısı: iki basamaklı toplama sorusu, doğru cevapta ayarlar.
/// [verifyOnly] ise ayarlar açılmaz, doğru cevapta `true` ile kapanır.
class ParentGateDialog extends StatefulWidget {
  const ParentGateDialog({super.key, this.verifyOnly = false});

  final bool verifyOnly;

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const ParentGateDialog(),
  );

  /// Yalnızca kapı: ebeveyn doğru cevaplarsa true.
  static Future<bool> verify(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => const ParentGateDialog(verifyOnly: true),
      ) ??
      false;

  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  final _random = Random();
  late int _a, _b;
  String _input = '';
  bool _wrong = false;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    _a = 10 + _random.nextInt(40);
    _b = 10 + _random.nextInt(40);
    _input = '';
  }

  void _digit(int d) {
    if (_input.length >= 3) return;
    setState(() {
      _input += '$d';
      _wrong = false;
    });
  }

  void _delete() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _submit() {
    if (widget.verifyOnly && int.tryParse(_input) == _a + _b) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      if (int.tryParse(_input) == _a + _b) {
        _unlocked = true;
      } else {
        _wrong = true;
        _newQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panel,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _unlocked ? const _SettingsPanel() : _gate(),
        ),
      ),
    );
  }

  Widget _gate() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.parentGateTitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.parentQuestion(_a, _b),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 140,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _input,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 28,
          child: _wrong
              ? Center(
                  child: Text(
                    context.l10n.wrongAnswer,
                    style: TextStyle(
                      color: AppColors.activeHighlight,
                      fontSize: 14,
                    ),
                  ),
                )
              : null,
        ),
        for (final row in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          _keyRow([for (final d in row) _key('$d', () => _digit(d))]),
        _keyRow([
          _key(context.l10n.delete, _delete, icon: Icons.backspace_outlined),
          _key('0', () => _digit(0)),
          _key(context.l10n.ok, _input.isEmpty ? null : _submit, primary: true),
        ]),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.l10n.close,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _keyRow(List<Widget> keys) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: keys[i]),
        ],
      ],
    ),
  );

  Widget _key(
    String label,
    VoidCallback? onTap, {
    bool primary = false,
    IconData? icon,
  }) {
    final child = icon == null
        ? AppButton(label: label, primary: primary, onPressed: onTap)
        : Semantics(
            label: label,
            button: true,
            excludeSemantics: true,
            child: AppButton(
              label: '',
              icon: icon,
              primary: primary,
              onPressed: onTap,
            ),
          );
    return child;
  }
}

class _SettingsPanel extends StatefulWidget {
  const _SettingsPanel();

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  bool _resetDone = false;

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text(
          context.l10n.resetConfirmTitle,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 22),
        ),
        content: Text(
          context.l10n.resetConfirmBody,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.l10n.cancel,
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.reset,
              style: TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final sessions = context.read<SessionRepository>();
    await context.read<ProgressController>().reset();
    await sessions.clearAll();
    if (mounted) setState(() => _resetDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.settings,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.l10n.sound,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          value: settings.soundOn,
          activeThumbColor: AppColors.primaryButtonText,
          activeTrackColor: AppColors.primaryButton,
          onChanged: settings.setSoundOn,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.ageRangeTitle,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        SegmentedButton<AgeGroup>(
          showSelectedIcon: false,
          segments: [
            for (final age in AgeGroup.values)
              ButtonSegment(
                value: age,
                label: Text(context.l10n.ageShortOf(age)),
              ),
          ],
          selected: {settings.ageGroup},
          onSelectionChanged: (s) => settings.setAgeGroup(s.first),
          style: SegmentedButton.styleFrom(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            selectedBackgroundColor: AppColors.primaryButton,
            selectedForegroundColor: AppColors.primaryButtonText,
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: context.l10n.resetProgress,
          primary: false,
          icon: Icons.restart_alt,
          onPressed: _resetDone ? null : _confirmReset,
        ),
        if (_resetDone)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.l10n.resetDone,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.activeHighlight, fontSize: 14),
            ),
          ),
        const SizedBox(height: 16),
        AppButton(
          label: context.l10n.rateApp,
          primary: false,
          icon: Icons.star_rounded,
          onPressed: () => context.read<ReviewService>().openStore(),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.about,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: context.l10n.close,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
