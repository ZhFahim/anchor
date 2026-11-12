import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../motion/haptics.dart';
import '../motion/snapshot_scale.dart';
import '../motion/springs.dart';
import '../theme/app_typography.dart';
import '../theme/context_extensions.dart';
import '../theme/tokens/anchor_tokens.dart';
import 'app_buttons.dart';
import 'balanced_text.dart';

Future<bool> showAnchorDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool hasCancel = true,
  IconData? icon,
  bool isDanger = false,
  Future<void> Function()? onConfirm,
  String? busyLabel,
}) async {
  if (isDanger) {
    Haptics.warning();
  } else {
    Haptics.light();
  }
  final colors = context.anchor;
  final cancel = hasCancel ? cancelLabel ?? context.l10n.commonCancel : null;
  final result = await Navigator.of(context, rootNavigator: true).push(
    _DialogRoute<bool>(
      barrierDismissible: true,
      barrierLabel: cancel ?? context.l10n.commonClose,
      barrierColor: colors.appOverlay,
      transitionDuration: Spring.snappy.duration,
      pageBuilder: (context, _, _) => _AnchorDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancel,
        icon: icon,
        isDanger: isDanger,
        onConfirm: onConfirm,
        busyLabel: busyLabel,
      ),
      transitionBuilder: (context, animation, _, child) {
        final scale = animation.status == AnimationStatus.reverse
            ? Tween<double>(begin: 0.96, end: 1).animate(animation)
            : Tween<double>(begin: 0.9, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Spring.snappy.curve),
              );
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AnchorTokens.motionEaseStandard,
          ),
          child: context.isMotionReduced
              ? child
              : AnimatedBuilder(
                  animation: scale,
                  builder: (context, child) =>
                      SnapshotScale(scale: scale.value, child: child!),
                  child: child,
                ),
        );
      },
    ),
  );
  return result ?? false;
}

class _DialogRoute<T> extends RawDialogRoute<T> {
  _DialogRoute({
    required super.pageBuilder,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.transitionDuration,
    super.transitionBuilder,
  });

  @override
  Duration get reverseTransitionDuration => AnchorTokens.motionDurationExit;
}

class _AnchorDialog extends StatefulWidget {
  const _AnchorDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.isDanger,
    required this.onConfirm,
    required this.busyLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final IconData? icon;
  final bool isDanger;

  final Future<void> Function()? onConfirm;
  final String? busyLabel;

  @override
  State<_AnchorDialog> createState() => _AnchorDialogState();
}

class _AnchorDialogState extends State<_AnchorDialog> {
  bool _isBusy = false;

  Future<void> _confirm() async {
    final onConfirm = widget.onConfirm;
    if (onConfirm != null) setState(() => _isBusy = true);
    try {
      await onConfirm?.call();
    } finally {
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final icon = widget.icon;
    final isDanger = widget.isDanger;
    final colors = context.anchor;
    final density = context.density;
    final cupertino = context.isCupertino;
    final align = cupertino
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = cupertino ? TextAlign.center : TextAlign.start;
    final dialog = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 320, // off-scale: a dialog's widest
          ),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  density.space24,
                  16,
                  density.space16,
                ),
                decoration: BoxDecoration(
                  color: colors.appSurface,
                  borderRadius: BorderRadius.circular(AnchorTokens.radius4xl),
                  boxShadow: colors.shadowDialog,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: align,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDanger
                              ? colors.statusDanger.withValues(alpha: 0.12)
                              : colors.appText.withValues(alpha: 0.07),
                        ),
                        child: Icon(
                          icon,
                          size: AnchorTokens.sizeIconLarge,
                          color: isDanger
                              ? colors.statusDanger
                              : colors.appText,
                        ),
                      ),
                      SizedBox(height: density.space12),
                    ],
                    BalancedText(
                      title,
                      textAlign: textAlign,
                      style: AppTypography.sheetTitle.copyWith(
                        color: colors.appText,
                      ),
                    ),
                    SizedBox(height: density.space8),
                    Text(
                      widget.message,
                      textAlign: textAlign,
                      style: AppTypography.secondary.copyWith(
                        color: colors.appMuted,
                      ),
                    ),
                    SizedBox(height: density.space24),
                    _Actions(
                      confirmLabel: widget.confirmLabel,
                      cancelLabel: widget.cancelLabel,
                      isDanger: isDanger,
                      isBusy: _isBusy,
                      busyLabel: widget.busyLabel,
                      onConfirm: _confirm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return PopScope(canPop: !_isBusy, child: dialog);
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDanger,
    required this.isBusy,
    required this.busyLabel,
    required this.onConfirm,
  });

  final String confirmLabel;
  final String? cancelLabel;
  final bool isDanger;
  final bool isBusy;
  final String? busyLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final kind = isDanger ? AppButtonKind.danger : AppButtonKind.primary;
    final cancelPressed = isBusy
        ? null
        : () => Navigator.of(context).pop(false);
    final confirm = AppButton(
      label: confirmLabel,
      kind: kind,
      isBusy: isBusy,
      busyLabel: busyLabel,
      onPressed: onConfirm,
    );
    if (cancelLabel == null) return confirm;
    final cancel = AppButton(
      label: cancelLabel!,
      kind: AppButtonKind.secondary,
      onPressed: cancelPressed,
    );
    if (!context.isCupertino) {
      return SizedBox(
        width: double.infinity,
        child: OverflowBar(
          alignment: MainAxisAlignment.end,
          spacing: 12,
          overflowSpacing: context.density.space12,
          overflowAlignment: OverflowBarAlignment.end,
          overflowDirection: VerticalDirection.up,
          children: [
            AppButton(
              label: cancelLabel!,
              kind: AppButtonKind.secondary,
              isExpanded: false,
              size: AppButtonSize.medium,
              onPressed: cancelPressed,
            ),
            AppButton(
              label: confirmLabel,
              kind: kind,
              isExpanded: false,
              size: AppButtonSize.medium,
              isBusy: isBusy,
              busyLabel: busyLabel,
              onPressed: onConfirm,
            ),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - 12) / 2 - 48;
        final style = AppTypography.row.copyWith(fontWeight: FontWeight.w600);
        bool fits(String text) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          return painter.width <= half;
        }

        if (fits(confirmLabel) && fits(cancelLabel!)) {
          return Row(
            children: [
              Expanded(child: cancel),
              const SizedBox(width: 12),
              Expanded(child: confirm),
            ],
          );
        }
        return Column(
          spacing: context.density.space12,
          children: [confirm, cancel],
        );
      },
    );
  }
}
