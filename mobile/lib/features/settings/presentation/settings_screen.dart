import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/links/link_utils.dart';
import '../../../core/motion/haptics.dart';
import '../../../core/motion/springs.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/network/server_address.dart';
import '../../../core/network/server_config_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/display_density.dart';
import '../../../core/theme/note_typography.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/anchor_dialog.dart';
import '../../../core/widgets/anchor_logo.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/check_circle.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/person_avatar.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../core/widgets/switch_row.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/oidc_config_provider.dart';
import '../../notes/presentation/notes_controller.dart';
import '../../server/data/server_info_provider.dart';
import '../../sync/data/sync_compatibility.dart';
import '../../sync/presentation/compatibility_messages.dart';
import 'editor_preferences_controller.dart';
import 'theme_preferences_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final gap = SizedBox(height: Section.gapOf(context));
    return AppScaffold(
      title: context.l10n.settingsTitle,
      background: PageBackground.gradient,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, context.density.space16, 16, 0),
          sliver: SliverList.list(
            children: [
              if (user != null) _AccountCard(user: user),
              gap,
              const _AppearanceSection(),
              gap,
              const _EditorSection(),
              gap,
              _AccountSection(user: user),
              gap,
              const _HelpSection(),
              _About(version: _version),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    return Pressable(
      style: PressStyle.profileCard,
      onTap: () => context.push(AppRoutes.editProfile),
      semanticLabel: context.l10n.settingsProfileCard(user.name, user.email),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: context.density.space16,
        ),
        decoration: BoxDecoration(
          color: colors.appSurface,
          borderRadius: BorderRadius.circular(AnchorTokens.radius2xl),
          boxShadow: colors.shadowXs,
        ),
        child: Row(
          spacing: 12,
          children: [
            PersonAvatar(
              name: user.name,
              imageUrl: user.profileImage,
              size: PersonAvatar.large,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.navTitle.copyWith(
                      color: colors.appText,
                    ),
                  ),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.secondary.copyWith(
                      color: colors.appMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: AnchorTokens.sizeIconSmall,
              color: colors.appMuted.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = ref.watch(displayDensityControllerProvider);
    final l10n = context.l10n;
    return Section(
      label: l10n.settingsAppearance,
      child: GroupedList(
        children: [
          const _ThemePicker(),
          StackedListTile(
            label: l10n.settingsDensity,
            subtitle: l10n.settingsDensityHelp,
            child: SegmentedControl<DisplayDensity>(
              semanticLabel: l10n.settingsDensity,
              value: density,
              segments: [
                for (final option in DisplayDensity.values)
                  Segment(value: option, label: option.labelIn(l10n)),
              ],
              onChanged: (option) => ref
                  .read(displayDensityControllerProvider.notifier)
                  .setDensity(option),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePicker extends ConsumerWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModeControllerProvider);
    final l10n = context.l10n;
    final modes = [
      (ThemeMode.light, l10n.themeLight),
      (ThemeMode.dark, l10n.themeDark),
      (ThemeMode.system, l10n.themeAutomatic),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: context.density.space16,
      ),
      child: Semantics(
        container: true,
        label: l10n.settingsTheme,
        child: Row(
          spacing: 12,
          children: [
            for (final (mode, label) in modes)
              Expanded(
                child: _ThemeTile(
                  mode: mode,
                  label: label,
                  isSelected: theme == mode,
                  onTap: () {
                    if (theme == mode) return;
                    Haptics.selection();
                    ref
                        .read(themeModeControllerProvider.notifier)
                        .setThemeMode(mode);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditorSection extends ConsumerWidget {
  const _EditorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorPreferencesControllerProvider);
    final controller = ref.read(editorPreferencesControllerProvider.notifier);
    final l10n = context.l10n;
    return Section(
      label: l10n.settingsEditor,
      child: GroupedList(
        children: [
          _EditorPreview(
            typography: NoteTypography(
              font: editor.noteFont,
              textSize: editor.noteTextSize,
              lineHeight: context.density.noteLineHeight,
            ),
          ),
          StackedListTile(
            label: l10n.settingsFont,
            child: SegmentedControl<NoteFont>(
              semanticLabel: l10n.settingsFont,
              value: editor.noteFont,
              segments: [
                for (final font in NoteFont.values)
                  Segment(
                    value: font,
                    label: font.labelIn(l10n),
                    fontFamily: font.family,
                  ),
              ],
              onChanged: controller.setNoteFont,
            ),
          ),
          StackedListTile(
            label: l10n.settingsTextSize,
            child: SegmentedControl<NoteTextSize>(
              semanticLabel: l10n.settingsTextSize,
              value: editor.noteTextSize,
              segments: [
                for (final size in NoteTextSize.values)
                  Segment(value: size, label: size.labelIn(l10n)),
              ],
              onChanged: controller.setNoteTextSize,
            ),
          ),
          SwitchRow(
            label: l10n.settingsMoveChecked,
            subtitle: l10n.settingsMoveCheckedHelp,
            value: editor.sortChecklistItems,
            onChanged: controller.setSortChecklistItems,
          ),
        ],
      ),
    );
  }
}

class _EditorPreview extends StatelessWidget {
  const _EditorPreview({required this.typography});

  final NoteTypography typography;

  @override
  Widget build(BuildContext context) {
    final color = context.anchor.appText;
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, context.density.space16, 16, 4),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: typography.scale),
          duration: context.motion(AnchorTokens.motionDurationFade),
          curve: AnchorTokens.motionEaseStandard,
          builder: (context, scale, _) {
            final shown = scale / typography.scale;
            TextStyle sized(TextStyle style) =>
                style.withSize(style.fontSize! * shown).copyWith(color: color);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  context.l10n.settingsPreviewTitle,
                  style: sized(typography.previewTitle),
                ),
                Text(
                  context.l10n.settingsPreviewText,
                  style: sized(typography.body),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection({required this.user});

  final User? user;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final unsynced = ref.read(unsyncedNoteCountProvider);
    await showAnchorDialog(
      context,
      title: context.l10n.settingsSignOutTitle,
      message: context.l10n.settingsSignOutMessage(unsynced),
      confirmLabel: context.l10n.settingsSignOut,
      busyLabel: context.l10n.settingsSigningOut,
      onConfirm: () => ref.read(authControllerProvider.notifier).logout(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oidc = ref.watch(oidcConfigProvider).value;
    final l10n = context.l10n;
    final managed = oidc?.enabled == true
        ? l10n.settingsPasswordManaged(oidc!.providerName)
        : l10n.settingsPasswordManagedElsewhere;
    return Section(
      label: l10n.settingsAccount,
      child: GroupedList(
        children: [
          if (user?.hasPassword ?? true)
            GroupedListTile(
              icon: LucideIcons.lock,
              label: l10n.settingsPassword,
              showChevron: true,
              onTap: () => context.push(AppRoutes.changePassword),
            )
          else
            GroupedListTile(
              icon: LucideIcons.keyRound,
              label: l10n.settingsPassword,
              subtitle: managed,
            ),
          GroupedListTile(
            icon: LucideIcons.logOut,
            label: l10n.settingsSignOut,
            isDanger: true,
            onTap: () => _signOut(context, ref),
          ),
          GroupedListTile(
            icon: LucideIcons.trash2,
            label: l10n.settingsDeleteAccount,
            isDanger: true,
            showChevron: true,
            onTap: () => context.push(AppRoutes.deleteAccount),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection();

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final l10n = context.l10n;
    return Section(
      label: l10n.settingsHelp,
      child: GroupedList(
        children: [
          GroupedListTile(
            icon: LucideIcons.scrollText,
            label: l10n.settingsLogs,
            subtitle: l10n.settingsLogsHelp,
            showChevron: true,
            onTap: () => context.push(AppRoutes.logs),
          ),
          if (defaultTargetPlatform != TargetPlatform.iOS)
            GroupedListTile(
              icon: LucideIcons.coffee,
              label: l10n.settingsSupport,
              subtitle: l10n.settingsSupportHelp,
              trailing: Icon(
                LucideIcons.arrowUpRight,
                size: AnchorTokens.sizeIconSmall,
                color: colors.appMuted.withValues(alpha: 0.7),
              ),
              onTap: () =>
                  launchExternal(context, 'https://www.buymeacoffee.com/zahid'),
            ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.mode,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final border = switch (mode) {
      ThemeMode.light => AnchorColors.light.appBorder,
      ThemeMode.dark => AnchorColors.dark.appBorder,
      ThemeMode.system => colors.appBorder,
    };
    final picture = switch (mode) {
      ThemeMode.light => const _AppIcon(colors: AnchorColors.light),
      ThemeMode.dark => const _AppIcon(colors: AnchorColors.dark),
      ThemeMode.system => const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _AppIcon(colors: AnchorColors.light, isNarrow: true)),
          Expanded(child: _AppIcon(colors: AnchorColors.dark, isNarrow: true)),
        ],
      ),
    };
    return Pressable(
      style: PressStyle.thumb,
      onTap: onTap,
      semanticLabel: label,
      selected: isSelected,
      child: Column(
        spacing: 8,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: math.min(constraints.maxWidth * 4 / 3, 132),
              // off-scale: a picture of the app
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AnchorTokens.radiusLg),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AnchorTokens.radiusLg),
                    border: Border.all(color: border),
                  ),
                  child: picture,
                ),
              ),
            ),
          ),
          Text(
            label,
            style: AppTypography.secondary.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: colors.appText,
            ),
          ),
          CheckCircle(
            value: isSelected,
            ringColor: colors.appMuted.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.colors, this.isNarrow = false});

  final AnchorColors colors;
  final bool isNarrow;

  static const _palettes = ['yellow', 'blue', 'none', 'green'];
  static const _heights = [30.0, 22.0, 22.0, 18.0];

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (var i = 0; i < (isNarrow ? 2 : 4); i++)
        Container(
          height: _heights[i],
          decoration: BoxDecoration(
            color: colors.notes[_palettes[i]]!.bg,
            borderRadius: BorderRadius.circular(
              5,
            ), // off-scale: a picture of the app
            border: Border.all(color: colors.notes[_palettes[i]]!.border),
          ),
        ),
    ];
    return Container(
      color: colors.appPage,
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 5 : 7,
        16,
        isNarrow ? 5 : 7,
        7,
      ), // off-scale: a picture of the app
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FractionallySizedBox(
            widthFactor: 0.56,
            child: Container(
              height: 6, // off-scale: a picture of the app
              decoration: BoxDecoration(
                color: colors.appText.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(
                  3,
                ), // off-scale: a picture of the app
              ),
            ),
          ),
          const SizedBox(height: 7), // off-scale: a picture of the app
          if (isNarrow)
            Column(spacing: 4, children: cards)
          else
            Column(
              spacing: 4,
              children: [
                for (final pair in [cards.sublist(0, 2), cards.sublist(2)])
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [for (final card in pair) Expanded(child: card)],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _About extends ConsumerWidget {
  const _About({required this.version});

  final String version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.anchor;
    final isOnline = ref.watch(isOnlineProvider);
    final url = ref.watch(serverUrlProvider);
    final info = ref.watch(serverInfoProvider).value;
    final compatibility = ref.watch(syncCompatibilityProvider).value;
    final mismatch = compatibility == null
        ? null
        : compatibilityMessagesOf(compatibility, context.l10n);
    final style = AppTypography.footnote.copyWith(color: colors.appMuted);
    final Widget server;
    if (!isOnline) {
      server = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Icon(
            LucideIcons.cloudOff,
            size: AnchorTokens.sizeIconSmall,
            color: colors.appMuted,
          ),
          Text(context.l10n.settingsOffline, style: style),
        ],
      );
    } else if (mismatch != null) {
      server = Pill(
        kind: PillKind.warn,
        icon: LucideIcons.triangleAlert,
        label: context.l10n.settingsSyncPaused(mismatch.lead),
      );
    } else if (url != null) {
      final host = hostOf(url);
      server = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Icon(
            info == null ? LucideIcons.cloudOff : LucideIcons.cloud,
            size: AnchorTokens.sizeIconSmall,
            color: colors.appMuted,
          ),
          Flexible(
            child: Text(
              switch (info?.version) {
                _ when info == null => context.l10n.settingsCantReach(host),
                final version? => context.l10n.settingsConnectedToVersion(
                  host,
                  version,
                ),
                null => context.l10n.settingsConnectedTo(host),
              },
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    } else {
      server = const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        context.density.space32,
        16,
        context.density.space8,
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: AnchorLogo(size: AnchorLogo.about),
          ),
          Text(
            version.isEmpty
                ? context.l10n.settingsAppNameShort
                : context.l10n.settingsAppVersion(version),
            style: AppTypography.secondary.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.appText,
            ),
          ),
          Text(context.l10n.settingsTagline, style: style),
          const SizedBox(height: 8),
          server,
        ],
      ),
    );
  }
}
