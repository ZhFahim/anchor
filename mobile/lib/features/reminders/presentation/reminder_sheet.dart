import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/haptics.dart';
import '../../../core/motion/springs.dart';
import '../../../core/text/date_formats.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/anchor_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/rolling_text.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../core/widgets/switch_row.dart';
import '../../../l10n/l10n.dart';
import '../../notes/domain/note.dart';
import '../domain/reminder_schedule.dart';
import '../domain/reminder_times.dart';
import 'month_grid.dart';
import 'reminder_labels.dart';
import 'time_wheel.dart';

/// `reminder: null` means removed; a dismissed sheet returns null.
typedef ReminderChoice = ({NoteReminder? reminder});

Future<ReminderChoice?> showReminderSheet(
  BuildContext context, {
  NoteReminder? reminder,
}) {
  return showAnchorSheet<ReminderChoice>(
    context,
    semanticLabel: context.l10n.reminderTitle,
    builder: (_) => _ReminderSheet(reminder: reminder),
  );
}

enum _Picker { date, time }

const _presetIcons = {
  ReminderPresetKind.laterToday: LucideIcons.clock,
  ReminderPresetKind.tomorrow: LucideIcons.sunrise,
  ReminderPresetKind.nextWeek: LucideIcons.calendarDays,
};

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({required this.reminder});

  final NoteReminder? reminder;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  final _pickerKey = GlobalKey();
  DateTime? _at;
  late ReminderRecurrence _repeat;
  ReminderRecurrence _lastRepeat = ReminderRecurrence.weekly;
  bool _isCustomTime = false;
  _Picker? _openPicker;
  late DateTime _month;
  late final List<ReminderPreset> _presets;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _at = parseWallClock(widget.reminder?.remindAt);
    _repeat = widget.reminder?.recurrence ?? ReminderRecurrence.none;
    if (_repeat.repeats) _lastRepeat = _repeat;
    _presets = reminderPresets(now);
    _isCustomTime =
        _at != null && !_presets.any((p) => isSameMinute(p.at, _at!));
    _month = DateTime((_at ?? now).year, (_at ?? now).month);
  }

  void _pickPreset(ReminderPreset preset) {
    setState(() {
      _at = preset.at;
      _isCustomTime = false;
      _openPicker = null;
    });
  }

  void _pickCustom() {
    setState(() {
      _isCustomTime = true;
      _at ??= tomorrowAtNine(DateTime.now());
      _month = DateTime(_at!.year, _at!.month);
      _openPicker = null;
    });
  }

  void _togglePicker(_Picker part) {
    Haptics.selection();
    setState(() => _openPicker = _openPicker == part ? null : part);
    if (_openPicker != null) {
      Timer(const Duration(milliseconds: 120), () {
        final target = _pickerKey.currentContext;
        if (target != null && target.mounted) {
          Scrollable.ensureVisible(
            target,
            duration: context.motion(Spring.smooth.duration),
            curve: Spring.smooth.curve,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
  }

  void _pickDay(DateTime day) {
    Haptics.selection();
    final base = _at ?? tomorrowAtNine(DateTime.now());
    setState(() {
      _at = DateTime(day.year, day.month, day.day, base.hour, base.minute);
      _openPicker = _Picker.time;
    });
  }

  void _setRepeating(bool on) {
    setState(() {
      if (on) {
        _repeat = _lastRepeat;
      } else {
        _lastRepeat = _repeat;
        _repeat = ReminderRecurrence.none;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final now = DateTime.now();
    final l10n = context.l10n;
    final summary = reminderSummary(_at, _repeat, now, l10n);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: l10n.reminderTitle,
          subtitle: l10n.reminderSheetSubtitle,
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: context.density.space16,
              children: [
                Semantics(
                  liveRegion: true,
                  label: context.l10n.joinSentences([
                    summary.headline,
                    summary.caption,
                  ]),
                  child: ExcludeSemantics(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: context.density.space16,
                      ),
                      decoration: BoxDecoration(
                        color: GroupedList.fillOf(context),
                        borderRadius: BorderRadius.circular(
                          AnchorTokens.radius2xl,
                        ),
                      ),
                      child: Column(
                        children: [
                          RollingText(
                            summary.headline,
                            style: AppTypography.sheetTitle.tabular.copyWith(
                              color: summary.isPast
                                  ? colors.statusDanger
                                  : _at == null
                                  ? colors.appMuted
                                  : colors.appText,
                            ),
                          ),
                          RollingText(
                            summary.caption,
                            style: AppTypography.secondary.copyWith(
                              color: summary.isPast
                                  ? colors.statusDanger
                                  : colors.appMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GroupedList(
                  semanticLabel: l10n.reminderWhen,
                  children: [
                    for (final preset in _presets)
                      GroupedListTile(
                        icon: _presetIcons[preset.kind]!,
                        label: presetLabel(preset, l10n),
                        value: presetValueLabel(preset, l10n),
                        checked:
                            !_isCustomTime &&
                            _at != null &&
                            isSameMinute(preset.at, _at!),
                        onTap: () => _pickPreset(preset),
                      ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GroupedListTile(
                          icon: LucideIcons.calendarClock,
                          label: l10n.reminderPickDate,
                          checked: _isCustomTime,
                          onTap: _pickCustom,
                        ),
                        Reveal(
                          visible: _isCustomTime,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  GroupedListTile.textStart,
                                  0,
                                  16,
                                  context.density.space16,
                                ),
                                child: Row(
                                  spacing: 8,
                                  children: [
                                    PillButton(
                                      icon: LucideIcons.calendar,
                                      label: _at == null
                                          ? l10n.reminderDate
                                          : reminderDateLabel(_at!),
                                      isOn: _openPicker == _Picker.date,
                                      onPressed: () =>
                                          _togglePicker(_Picker.date),
                                    ),
                                    PillButton(
                                      icon: LucideIcons.clock,
                                      label: _at == null
                                          ? l10n.reminderTime
                                          : clockLabel(_at!),
                                      isOn: _openPicker == _Picker.time,
                                      onPressed: () =>
                                          _togglePicker(_Picker.time),
                                    ),
                                  ],
                                ),
                              ),
                              Reveal(
                                visible: _openPicker != null,
                                child: Padding(
                                  key: _pickerKey,
                                  padding: EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    12,
                                    context.density.space12,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: context.motion(
                                      AnchorTokens.motionDurationFade,
                                    ),
                                    child: switch (_openPicker) {
                                      _Picker.date => MonthGrid(
                                        key: const ValueKey('date'),
                                        month: _month,
                                        selected: _at,
                                        now: now,
                                        onDay: _pickDay,
                                        onMonth: (m) =>
                                            setState(() => _month = m),
                                      ),
                                      _Picker.time => TimeWheel(
                                        key: const ValueKey('time'),
                                        at: _at ?? tomorrowAtNine(now),
                                        onChanged: (t) => setState(() {
                                          final day =
                                              _at ?? tomorrowAtNine(now);
                                          _at = DateTime(
                                            day.year,
                                            day.month,
                                            day.day,
                                            t.hour,
                                            t.minute,
                                          );
                                        }),
                                      ),
                                      null => const SizedBox(
                                        width: double.infinity,
                                      ),
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GroupedList(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchRow(
                          icon: LucideIcons.repeat,
                          label: l10n.reminderRepeat,
                          value: _repeat.repeats,
                          onChanged: _setRepeating,
                        ),
                        Reveal(
                          visible: _repeat.repeats,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              12,
                              0,
                              12,
                              context.density.space12,
                            ),
                            child: SegmentedControl<ReminderRecurrence>(
                              semanticLabel: l10n.reminderRepeat,
                              value: _repeat.repeats ? _repeat : _lastRepeat,
                              segments: [
                                for (final recurrence
                                    in ReminderRecurrence.values.where(
                                      (r) => r.repeats,
                                    ))
                                  Segment(
                                    value: recurrence,
                                    label: repeatLabel(recurrence, l10n),
                                  ),
                              ],
                              onChanged: (r) =>
                                  setState(() => _repeat = _lastRepeat = r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SheetFooter(
          children: [
            AppButton(
              label: widget.reminder == null
                  ? l10n.commonCancel
                  : l10n.reminderRemove,
              kind: AppButtonKind.secondary,
              onPressed: () => Navigator.of(context).pop<ReminderChoice>(
                widget.reminder == null ? null : (reminder: null),
              ),
            ),
            AppButton(
              label: l10n.commonSave,
              onPressed: summary.canSave
                  ? () => Navigator.of(context).pop<ReminderChoice>((
                      reminder: NoteReminder(
                        remindAt: toWallClock(_at!),
                        recurrence: _repeat,
                        version: widget.reminder?.version ?? 0,
                      ),
                    ))
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
