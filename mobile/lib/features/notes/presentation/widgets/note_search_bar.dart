import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../l10n/l10n.dart';
import '../editor/note_search.dart';

/// The note's top bar while a search is open: a field, a counter, two arrows
/// and a close button.
class NoteSearchBar extends StatefulWidget {
  const NoteSearchBar({
    super.key,
    required this.search,
    required this.background,
    required this.onQueryChanged,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
  });

  final NoteSearch search;
  final Color background;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;

  @override
  State<NoteSearchBar> createState() => _NoteSearchBarState();
}

class _NoteSearchBarState extends State<NoteSearchBar> {
  final _field = TextEditingController();
  final _focus = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  String? get _counter {
    if (widget.search.isEmpty) return null;
    if (!widget.search.hasMatches) return context.l10n.noteSearchNoResults;
    final count = widget.search.matches.length;
    final shown = count >= maxSearchMatches ? '$maxSearchMatches+' : '$count';
    return '${widget.search.active + 1}/$shown';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasMatches = widget.search.hasMatches;
    return Material(
      color: widget.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AnchorTokens.space8,
            vertical: AnchorTokens.space8,
          ),
          child: Row(
            spacing: 4,
            children: [
              BarButton(
                icon: LucideIcons.arrowLeft,
                label: l10n.noteSearchClose,
                onPressed: widget.onClose,
              ),
              Expanded(
                child: TextField(
                  controller: _field,
                  focusNode: _focus,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: widget.onQueryChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: l10n.noteSearchHint,
                  ),
                ),
              ),
              if (_counter case final counter?)
                Text(counter, style: Theme.of(context).textTheme.labelMedium),
              BarButton(
                icon: LucideIcons.arrowUp,
                label: l10n.noteSearchPrevious,
                onPressed: hasMatches ? widget.onPrevious : null,
              ),
              BarButton(
                icon: LucideIcons.arrowDown,
                label: l10n.noteSearchNext,
                onPressed: hasMatches ? widget.onNext : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
