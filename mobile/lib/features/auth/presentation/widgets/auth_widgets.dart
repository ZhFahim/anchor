import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/expanded_hit_area.dart';
import '../../../../core/widgets/grouped_list.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../l10n/l10n.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    Widget line() => Expanded(
      child: Container(
        height: 1,
        color: colors.appBorder.withValues(alpha: 0.9),
      ),
    );
    return Row(
      spacing: 12,
      children: [
        line(),
        Text(
          context.l10n.authOr,
          style: AppTypography.secondary.copyWith(color: colors.appMuted),
        ),
        line(),
      ],
    );
  }
}

class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    return Padding(
      padding: const EdgeInsets.only(top: AnchorTokens.space4),
      child: ExpandedHitArea(
        padding: const EdgeInsets.symmetric(vertical: AnchorTokens.space12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$text ',
              style: AppTypography.secondary.copyWith(color: colors.appMuted),
            ),
            Pressable(
              style: PressStyle.plain,
              onTap: onTap,
              semanticLabel: action,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AnchorTokens.space4,
                ),
                child: Text(
                  action,
                  style: AppTypography.secondary.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.accentInk,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A link on its own line, like the ones under a form's button.
class AuthTextLink extends StatelessWidget {
  const AuthTextLink({super.key, required this.label, this.onTap});

  final String label;

  /// Null shows it as unavailable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    return ExpandedHitArea(
      padding: const EdgeInsets.symmetric(vertical: AnchorTokens.space12),
      child: Center(
        child: Pressable(
          style: PressStyle.plain,
          onTap: onTap,
          semanticLabel: label,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AnchorTokens.space4,
            ),
            child: Text(
              label,
              style: AppTypography.secondary.copyWith(
                fontWeight: FontWeight.w600,
                color: onTap == null ? colors.appMuted : colors.accentInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The digits of a code in a row of boxes. One text field that shows nothing
/// itself takes the typing, so the keyboard's code suggestion and paste work.
class CodeBoxes extends StatelessWidget {
  const CodeBoxes({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.semanticLabel,
    this.length = 6,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// What screen readers call the field.
  final String semanticLabel;

  final int length;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  static const double _height = 60;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final fill = GroupedList.fillOf(context);
    return SizedBox(
      height: _height,
      child: Stack(
        children: [
          ExcludeSemantics(
            child: ListenableBuilder(
              listenable: Listenable.merge([controller, focusNode]),
              builder: (context, _) {
                final digits = controller.text;
                final active = enabled && focusNode.hasFocus
                    ? digits.length
                    : -1;
                return Row(
                  spacing: _gap,
                  children: [
                    for (var index = 0; index < length; index++)
                      Expanded(
                        child: Opacity(
                          opacity: enabled ? 1 : DisabledOpacity.button,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: enabled
                                  ? fill
                                  : colors.appText.withValues(alpha: 0.04),
                              border: hasError
                                  ? Border.all(
                                      color: colors.statusDanger,
                                      width: 2,
                                    )
                                  : index == active
                                  ? Border.all(
                                      color: colors.accentStrong,
                                      width: 2,
                                    )
                                  : Border.all(color: colors.appFieldLine),
                              borderRadius: BorderRadius.circular(
                                AnchorTokens.radius2xl,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                index < digits.length ? digits[index] : '',
                                style: AppTypography.sheetTitle.copyWith(
                                  color: colors.appText,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Positioned.fill(
            child: Semantics(
              label: semanticLabel,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                autocorrect: false,
                enableSuggestions: false,
                showCursor: false,
                enableInteractiveSelection: false,
                maxLength: length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.transparent),
                cursorColor: Colors.transparent,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  fillColor: Colors.transparent,
                ),
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
