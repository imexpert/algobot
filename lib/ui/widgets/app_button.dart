import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Düz, gölgesiz birincil/ikincil buton. En az 48dp yükseklik.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? AppColors.primaryButton : AppColors.secondaryButton;
    final fg = primary
        ? AppColors.primaryButtonText
        : AppColors.secondaryButtonText;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height, minWidth: 48),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.4),
          disabledForegroundColor: fg.withValues(alpha: 0.6),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontSize: primary ? 18 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// Küçük açma/kapama hapı ("Adım adım", "Hızlı").
class TogglePill extends StatelessWidget {
  const TogglePill({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final bg = value ? AppColors.primaryButton : AppColors.secondaryButton;
    final fg = value
        ? AppColors.primaryButtonText
        : AppColors.secondaryButtonText;
    return Semantics(
      toggled: value,
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: bg,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: enabled ? () => onChanged!(!value) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
