import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/app_durations.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_opacity.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/settings_card.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../domain/note.dart';
import '../../domain/reminder_schedule.dart';

/// Picks when a note rings and how often.
class ReminderPickerSheet extends StatefulWidget {
  const ReminderPickerSheet({
    super.key,
    required this.reminder,
    required this.onReminderChanged,
  });

  final NoteReminder? reminder;
  final ValueChanged<NoteReminder?> onReminderChanged;

  @override
  State<ReminderPickerSheet> createState() => _ReminderPickerSheetState();
}

class _ReminderPickerSheetState extends State<ReminderPickerSheet> {
  DateTime? _at;
  late ReminderRecurrence _recurrence;
  bool _custom = false;

  /// Restored when the repeat switch goes back on.
  ReminderRecurrence _lastRepeat = ReminderRecurrence.daily;

  /// Resolved once, so a preset holds still while the sheet is open.
  late final List<_Preset> _presets;

  @override
  void initState() {
    super.initState();
    final at = parseWallClock(widget.reminder?.remindAt);
    _at = at;
    _recurrence = widget.reminder?.recurrence ?? ReminderRecurrence.none;
    if (_recurrence != ReminderRecurrence.none) _lastRepeat = _recurrence;
    _presets = _buildPresets(DateTime.now());
    _custom =
        at != null && !_presets.any((preset) => _sameMinute(at, preset.at));
  }

  void _choosePreset(DateTime at) {
    HapticFeedback.selectionClick();
    setState(() {
      _at = at;
      _custom = false;
    });
  }

  void _openCustom() {
    HapticFeedback.selectionClick();
    setState(() {
      _custom = true;
      // Seeded so the fields open on a real value.
      _at ??= _defaultSeed(DateTime.now());
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final seed = _at ?? _defaultSeed(now);

    final date = await showDatePicker(
      context: context,
      initialDate: seed,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null) return;

    var at = DateTime(date.year, date.month, date.day, seed.hour, seed.minute);
    if (at.isBefore(now)) at = _nextRoundTimeOn(at, now);
    setState(() => _at = at);
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final seed = _at ?? _defaultSeed(now);

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: seed.hour, minute: seed.minute),
    );
    if (time == null) return;

    final day = _at ?? now;
    setState(() {
      _at = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    });
  }

  void _setRepeating(bool repeats) {
    setState(() {
      if (repeats) {
        _recurrence = _lastRepeat;
      } else {
        _lastRepeat = _recurrence;
        _recurrence = ReminderRecurrence.none;
      }
    });
  }

  void _save() {
    final at = _at;
    if (at == null) return;
    widget.onReminderChanged(
      NoteReminder(
        remindAt: toWallClock(at),
        recurrence: _recurrence,
        version: widget.reminder?.version ?? 0,
      ),
    );
    Navigator.of(context).pop();
  }

  void _remove() {
    widget.onReminderChanged(null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;
    final at = _at;
    final repeats = _recurrence != ReminderRecurrence.none;

    return AppBottomSheet(
      icon: LucideIcons.bell,
      title: 'Reminder',
      subtitle: 'Reminds you on your devices at this time, wherever you are.',
      maxHeightFactor: 0.9,
      contentPadding: EdgeInsets.fromLTRB(dims.xl, 0, dims.xl, dims.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The options scroll; the actions stay put.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Summary(at: at, recurrence: _recurrence),
                  SizedBox(height: dims.md),
                  SettingsCard(
                    child: Column(
                      children: [
                        for (final preset in _presets) ...[
                          _WhenRow(
                            icon: preset.icon,
                            label: preset.label,
                            value: DateFormat.jm().format(preset.at),
                            selected:
                                !_custom &&
                                at != null &&
                                _sameMinute(at, preset.at),
                            onTap: () => _choosePreset(preset.at),
                          ),
                          const SettingsDivider(),
                        ],
                        _WhenRow(
                          icon: LucideIcons.calendarClock,
                          label: 'Pick a date',
                          selected: _custom,
                          onTap: _openCustom,
                        ),
                        _Reveal(
                          visible: _custom,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              dims.sm,
                              0,
                              dims.sm,
                              dims.sm,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _Field(
                                    icon: LucideIcons.calendar,
                                    value: at == null
                                        ? ''
                                        : DateFormat.MMMEd().format(at),
                                    onTap: _pickDate,
                                  ),
                                ),
                                SizedBox(width: dims.xs),
                                Expanded(
                                  child: _Field(
                                    icon: LucideIcons.clock,
                                    value: at == null
                                        ? ''
                                        : DateFormat.jm().format(at),
                                    onTap: _pickTime,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: dims.md),
                  SettingsCard(
                    child: Column(
                      children: [
                        _RepeatRow(value: repeats, onChanged: _setRepeating),
                        _Reveal(
                          visible: repeats,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SettingsDivider(),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  dims.md,
                                  dims.sm,
                                  dims.md,
                                  dims.sm,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: dims.xs,
                                      runSpacing: dims.xs,
                                      children: [
                                        for (final value in _repeatOptions)
                                          _Chip(
                                            label: value.label,
                                            selected: _recurrence == value,
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setState(
                                                () => _recurrence = value,
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: dims.sm),
          SheetActionButtons(
            cancelText: widget.reminder == null ? 'Cancel' : 'Remove',
            confirmText: 'Save',
            onCancel: widget.reminder == null
                ? () => Navigator.of(context).pop()
                : _remove,
            onConfirm: at == null ? null : _save,
          ),
        ],
      ),
    );
  }
}

/// The reminder as it currently stands, in one sentence.
class _Summary extends StatelessWidget {
  const _Summary({required this.at, required this.recurrence});

  final DateTime? at;
  final ReminderRecurrence recurrence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    final onSurface = theme.colorScheme.onSurface;

    final at = this.at;
    final next = at == null
        ? null
        : nextOccurrence(
            NoteReminder(remindAt: toWallClock(at), recurrence: recurrence),
            from: DateTime.now(),
          );

    final (String headline, String caption, bool isPast) = switch ((at, next)) {
      (null, _) => ('No time set', 'Choose when to be reminded', false),
      (final chosen?, null) => (
        _formatHeadline(chosen),
        'Already passed',
        true,
      ),
      (final chosen?, final upcoming?) => (
        _formatHeadline(upcoming),
        _repeatCaption(chosen, recurrence),
        false,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(vertical: dims.sm, horizontal: dims.md),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: AppOpacity.hairline),
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        children: [
          _RollingText(
            text: headline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: at == null
                  ? onSurface.withValues(alpha: AppOpacity.disabled)
                  : onSurface,
            ),
          ),
          SizedBox(height: dims.xxs),
          _RollingText(
            text: caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isPast
                  ? theme.colorScheme.error
                  : onSurface.withValues(alpha: AppOpacity.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Text that rolls vertically when it changes: the old line leaves upwards,
/// the new one arrives from below, both clipped to one line's window.
class _RollingText extends StatelessWidget {
  const _RollingText({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final key = ValueKey(text);

    return ClipRect(
      child: AnimatedSwitcher(
        duration: AppDurations.slow,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final arriving = child.key == key;
          return SlideTransition(
            position: Tween(
              begin: Offset(0, arriving ? 1 : -1),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Text(
          text,
          key: key,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }
}

/// One option in the list of times: a label, what it resolves to, and a check.
class _WhenRow extends StatelessWidget {
  const _WhenRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    final accent = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(
      alpha: AppOpacity.secondary,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdBorder,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dims.lg, vertical: dims.sm),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppIconSizes.md,
                color: selected ? accent : muted,
              ),
              SizedBox(width: dims.md),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: selected ? accent : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              SizedBox(width: dims.xs),
              AnimatedOpacity(
                duration: AppDurations.fast,
                opacity: selected ? 1 : 0,
                child: Icon(
                  LucideIcons.check,
                  size: AppIconSizes.md,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grows a section into place, and takes it out of the tree when hidden.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: visible
          ? child
          : const SizedBox(width: double.infinity, height: 0),
    );
  }
}

/// The repeat switch.
class _RepeatRow extends StatelessWidget {
  const _RepeatRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    final accent = theme.colorScheme.primary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dims.lg, vertical: dims.xxs),
      child: Row(
        children: [
          Icon(
            LucideIcons.repeat,
            size: AppIconSizes.md,
            color: value
                ? accent
                : theme.colorScheme.onSurface.withValues(
                    alpha: AppOpacity.secondary,
                  ),
          ),
          SizedBox(width: dims.md),
          Expanded(
            child: Text(
              'Repeat',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: value ? accent : theme.colorScheme.onSurface,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (next) {
              HapticFeedback.selectionClick();
              onChanged(next);
            },
            activeTrackColor: accent,
            activeThumbColor: theme.colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}

/// A pill that selects one option.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.colorTokens;
    final dims = context.dims;
    final accent = theme.colorScheme.primary;

    return AnimatedContainer(
      duration: AppDurations.fast,
      decoration: BoxDecoration(
        color: selected
            ? accent.withValues(alpha: AppOpacity.subtleFill)
            : tokens.inputFill,
        borderRadius: AppRadius.smBorder,
        border: Border.all(
          color: selected
              ? accent.withValues(alpha: AppOpacity.border)
              : tokens.subtleBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smBorder,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dims.sm,
              vertical: dims.xs,
            ),
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected ? accent : theme.colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A field that opens one of the platform pickers.
class _Field extends StatelessWidget {
  const _Field({required this.icon, required this.value, required this.onTap});

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.colorTokens;
    final dims = context.dims;
    final muted = theme.colorScheme.onSurface.withValues(
      alpha: AppOpacity.secondary,
    );

    return Material(
      color: tokens.inputFill,
      borderRadius: AppRadius.smBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smBorder,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: dims.sm, vertical: dims.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smBorder,
            border: Border.all(color: tokens.subtleBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppIconSizes.sm, color: muted),
              SizedBox(width: dims.xs),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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

class _Preset {
  const _Preset(this.label, this.at, this.icon);

  final String label;
  final DateTime at;
  final IconData icon;
}

/// Presets in the order the day runs, dropping "Later today" once it would
/// spill past midnight.
List<_Preset> _buildPresets(DateTime now) {
  final laterToday = _roundToFive(now.add(const Duration(hours: 3)));
  final tomorrow = DateTime(now.year, now.month, now.day + 1, 9);
  final nextWeek = DateTime(now.year, now.month, now.day + 7, 9);

  return [
    if (laterToday.day == now.day)
      _Preset('Later today', laterToday, LucideIcons.clock),
    _Preset('Tomorrow', tomorrow, LucideIcons.sunrise),
    _Preset('Next week', nextWeek, LucideIcons.calendarDays),
  ];
}

const _repeatOptions = [
  ReminderRecurrence.daily,
  ReminderRecurrence.weekly,
  ReminderRecurrence.monthly,
  ReminderRecurrence.yearly,
];

DateTime _roundToFive(DateTime at) {
  final minute = (at.minute / 5).ceil() * 5;
  return DateTime(
    at.year,
    at.month,
    at.day,
    at.hour,
  ).add(Duration(minutes: minute));
}

/// [day] at the next five-minute mark that is at least five minutes out.
DateTime _nextRoundTimeOn(DateTime day, DateTime now) {
  final at = _roundToFive(now.add(const Duration(minutes: 5)));
  // Late enough at night the rounding spills into tomorrow.
  if (at.day != now.day) return DateTime(day.year, day.month, day.day, 23, 59);
  return DateTime(day.year, day.month, day.day, at.hour, at.minute);
}

DateTime _defaultSeed(DateTime now) =>
    DateTime(now.year, now.month, now.day + 1, 9);

bool _sameMinute(DateTime a, DateTime b) =>
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day &&
    a.hour == b.hour &&
    a.minute == b.minute;

/// "Today, 6:00 PM" / "Tomorrow, 9:00 AM" / "Sat, Sep 12, 9:00 AM".
String _formatHeadline(DateTime at) {
  final now = DateTime.now();
  final days = DateTime(
    at.year,
    at.month,
    at.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;

  final day = switch (days) {
    0 => 'Today',
    1 => 'Tomorrow',
    _ when at.year == now.year => DateFormat.MMMEd().format(at),
    _ => DateFormat.yMMMEd().format(at),
  };
  return '$day, ${DateFormat.jm().format(at)}';
}

/// The rule behind the time in the headline, naming what it is anchored to.
String _repeatCaption(DateTime at, ReminderRecurrence recurrence) =>
    switch (recurrence) {
      ReminderRecurrence.none => 'Just once',
      ReminderRecurrence.daily => 'Then every day',
      ReminderRecurrence.weekly => 'Then every ${DateFormat.EEEE().format(at)}',
      // Short months clamp to their last day rather than rolling forward.
      ReminderRecurrence.monthly =>
        at.day > 28
            ? "Then day ${at.day}, or the month's last day"
            : 'Then day ${at.day} of every month',
      ReminderRecurrence.yearly => 'Then every ${DateFormat.MMMd().format(at)}',
    };
