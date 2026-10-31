import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/springs.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/anchor_sheet.dart';
import '../../../../core/widgets/grouped_list.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/selection_ring.dart';
import '../../../../l10n/l10n.dart';
import 'note_surface.dart';

Future<void> showBackgroundSheet(
  BuildContext context, {
  required String? current,
  required ValueChanged<String?> onChanged,
}) {
  return showAnchorSheet<void>(
    context,
    semanticLabel: context.l10n.noteBackground,
    builder: (_) => _BackgroundSheet(current: current, onChanged: onChanged),
  );
}

class _BackgroundSheet extends StatefulWidget {
  const _BackgroundSheet({required this.current, required this.onChanged});

  final String? current;
  final ValueChanged<String?> onChanged;

  @override
  State<_BackgroundSheet> createState() => _BackgroundSheetState();
}

class _BackgroundSheetState extends State<_BackgroundSheet> {
  late String? _id = AnchorBackgrounds.of(widget.current).id;

  void _pick(String? id) {
    if (id == _id) return;
    Haptics.selection();
    setState(() => _id = id);
    widget.onChanged(id);
  }

  Widget _row(
    String label,
    List<AnchorBackground> items, {
    bool isSquare = false,
  }) {
    return Semantics(
      container: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = 12.0;
          final size = (box.maxWidth - gap * 5) / 6;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final background in items)
                _Swatch(
                  background: background,
                  size: size,
                  isSquare: isSquare,
                  on: background.id == _id,
                  onTap: () => _pick(background.id),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: context.l10n.noteBackground, showDone: true),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Section(
                  label: context.l10n.noteColor,
                  isBoxed: false,
                  child: _row(context.l10n.noteColor, AnchorBackgrounds.colors),
                ),
                SizedBox(height: Section.gapOf(context)),
                Section(
                  label: context.l10n.notePattern,
                  isBoxed: false,
                  child: _row(
                    context.l10n.notePattern,
                    AnchorBackgrounds.patterns,
                    isSquare: true,
                  ),
                ),
                const SheetBottomSpace(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.background,
    required this.size,
    required this.isSquare,
    required this.on,
    required this.onTap,
  });

  final AnchorBackground background;
  final double size;
  final bool isSquare;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final appearance = NoteAppearance(
      background: background,
      colors: colors.notes[background.palette]!,
    );

    final radius = isSquare
        ? BorderRadius.circular(AnchorTokens.radiusLg)
        : BorderRadius.circular(size);
    return Pressable(
      style: PressStyle.thumb,
      onTap: onTap,
      semanticLabel: _nameOf(background, context.l10n),
      selected: on,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: SelectionRing(
                isShown: on,
                borderRadius: radius,
                child: ClipRRect(
                  borderRadius: radius,
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: appearance.colors.border),
                    ),
                    child: NoteSurface(
                      appearance: appearance,
                      child: background.id == null
                          ? Center(
                              child: Icon(
                                LucideIcons.ban,
                                size: AnchorTokens.sizeIconMedium,
                                color: colors.appMuted,
                              ),
                            )
                          : const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -2, // off-scale: the chosen badge on a swatch
              bottom: -2, // off-scale: as above
              child: AnimatedScale(
                scale: on ? 1 : 0,
                duration: context.motion(Spring.pop.duration),
                curve: Spring.pop.curve,
                child: Container(
                  width: 20, // off-scale: the chosen badge on a swatch
                  height: 20, // off-scale: as above
                  decoration: BoxDecoration(
                    color: colors.accentStrong,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons600.check,
                    size: 12, // off-scale: as above
                    color: colors.checkMark,
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

String _nameOf(AnchorBackground background, AppLocalizations l10n) =>
    switch (background.id) {
      null => l10n.noteColorDefault,
      'color_yellow' => l10n.colorYellow,
      'color_orange' => l10n.colorOrange,
      'color_brown' => l10n.colorBrown,
      'color_red' => l10n.colorRed,
      'color_pink' => l10n.colorPink,
      'color_purple' => l10n.colorPurple,
      'color_dark_blue' => l10n.colorIndigo,
      'color_blue' => l10n.colorBlue,
      'color_teal' => l10n.colorTeal,
      'color_green' => l10n.colorGreen,
      'pattern_dots' => l10n.patternDots,
      'pattern_grid' => l10n.patternGrid,
      'pattern_lines' => l10n.patternLines,
      'pattern_waves' => l10n.patternWaves,
      'pattern_groceries' => l10n.patternGroceries,
      'pattern_music' => l10n.patternMusic,
      'pattern_travel' => l10n.patternTravel,
      'pattern_code' => l10n.patternCode,
      _ => background.name,
    };
