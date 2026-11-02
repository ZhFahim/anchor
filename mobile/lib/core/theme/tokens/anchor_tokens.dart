// Generated from design/tokens by design/build. Do not edit by hand.
//
// AnchorTokens holds what stays the same in light and dark. AnchorColors is a
// ThemeExtension with the rest, registered on both ThemeData. Text styles carry
// size, weight, height and spacing only; the font family comes from
// AppTypography.

// dart format off

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

abstract final class AnchorTokens {
  /// Dark slate: light text, primary and inverse
  static const Color colorBrandSlate = Color(0xFF2D3142);
  /// Slate blue: light secondary text
  static const Color colorBrandSlateBlue = Color(0xFF4F5D75);
  /// Between slate blue and mist
  static const Color colorBrandSlateGray = Color(0xFF6B7A8F);
  /// Dark secondary text
  static const Color colorBrandMist = Color(0xFF9CA8B8);
  /// Light page
  static const Color colorBrandCloud = Color(0xFFF0F4F8);
  /// Dark page
  static const Color colorBrandNight = Color(0xFF111214);
  /// Dark surface
  static const Color colorBrandDusk = Color(0xFF1C1D21);
  /// Dark text
  static const Color colorBrandOffWhite = Color(0xFFEAEAEA);
  /// White
  static const Color colorBrandWhite = Color(0xFFFFFFFF);
  /// Burnt orange, the accent
  static const Color colorBrandOrange = Color(0xFFEF8354);
  /// Large fills and tints only: text selection and the drop area
  static const Color colorAccentFill = Color(0xFFEF8354);
  /// The round knob of a switch
  static const Color colorControlKnob = Color(0xFFFFFFFF);
  static const Color colorAvatarRust = Color(0xFFA4522A);
  static const Color colorAvatarBlue = Color(0xFF3F6FA6);
  static const Color colorAvatarPurple = Color(0xFF8A4FA3);
  static const Color colorAvatarTeal = Color(0xFF2F7D6D);
  static const Color colorAvatarOlive = Color(0xFF6A6F2A);
  static const Color colorAvatarBrown = Color(0xFF7A4B2F);
  static const Color colorAvatarRose = Color(0xFFA13F5C);
  static const Color colorAvatarNavy = Color(0xFF3B5F8A);
  static const Color colorAvatarAmber = Color(0xFF9A5B16);
  static const Color colorAvatarIndigo = Color(0xFF4D5C9E);
  static const Color colorAvatarMoss = Color(0xFF556B2F);
  /// Initials on an avatar
  static const Color colorAvatarText = Color(0xFFFFFFFF);
  /// The cool glow behind the sign-in collage
  static const Color colorDecorGlow = Color(0xFF64B5F6);
  /// Behind the picture viewer
  static const Color colorMediaScrim = Color(0xF20C0E12);
  /// Over a picture, behind a count like +3
  static const Color colorMediaShade = Color(0x730C0E12);
  /// Behind a small count on a thumbnail
  static const Color colorMediaShadeStrong = Color(0x990C0E12);
  /// Text over pictures and in the viewer
  static const Color colorMediaText = Color(0xFFF1F2F4);
  /// Second lines in the viewer, 8.5 : 1 on its shade
  static const Color colorMediaMuted = Color(0xFFA9AFBB);
  /// Hints in the viewer, 6 : 1 on its shade
  static const Color colorMediaFaint = Color(0xFF8D94A1);
  /// Buttons in the viewer
  static const Color colorMediaControl = Color(0x1AFFFFFF);
  /// Those buttons when hovered
  static const Color colorMediaControlHover = Color(0x2EFFFFFF);
  /// A hairline inside a picture tile
  static const Color colorMediaEdge = Color(0x0F000000);
  static const double space0 = 0.0;
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;
  static const double space64 = 64.0;
  static const double space80 = 80.0;
  static const double space96 = 96.0;
  /// Mobile AppDimensions.xxs
  static const double spaceXxs = 4.0;
  /// Mobile AppDimensions.xs
  static const double spaceXs = 8.0;
  /// Mobile AppDimensions.sm
  static const double spaceSm = 12.0;
  /// Mobile AppDimensions.md
  static const double spaceMd = 16.0;
  /// Mobile AppDimensions.lg
  static const double spaceLg = 20.0;
  /// Mobile AppDimensions.xl
  static const double spaceXl = 24.0;
  /// Mobile AppDimensions.xxl
  static const double spaceXxl = 32.0;
  /// Side padding of a page on desktop
  static const double spaceGutter = 28.0;
  /// Side padding of a page on phones, the same as mobile's screenGutter
  static const double spaceGutterPhone = 16.0;
  /// Checkboxes, keyboard keys, small badges
  static const double radiusXs = 6.0;
  /// Menu items, small buttons, swatches
  static const double radiusSm = 8.0;
  /// Buttons, fields, rows in the sidebar
  static const double radiusMd = 10.0;
  /// Tiles and the floating bars on a note
  static const double radiusLg = 12.0;
  /// Grouped lists, picture cards, bars and menus
  static const double radiusXl = 14.0;
  /// Cards, panels and pop-overs
  static const double radius2xl = 16.0;
  /// Dialogs
  static const double radius3xl = 20.0;
  /// Phone: sheets, dialogs and the drawer
  static const double radius4xl = 28.0;
  /// Notes and note cards
  static const double radiusNote = 18.0;
  /// The floating new-note button, like mobile's AppRadius.fab
  static const double radiusFab = 18.0;
  /// Chips, badges, switches
  static const double radiusPill = 999.0;
  static const double radiusCheckbox = 6.0;
  static const double radiusMenuItem = 8.0;
  static const double radiusMenu = 14.0;
  static const double radiusPopover = 16.0;
  static const double radiusButton = 10.0;
  static const double radiusField = 10.0;
  static const double radiusTile = 12.0;
  static const double radiusFloating = 12.0;
  static const double radiusCard = 16.0;
  static const double radiusDialog = 20.0;
  static const double radiusSheet = 28.0;
  /// The smallest anything clickable may be (WCAG 2.2, 2.5.8)
  static const double sizeTargetMin = 24.0;
  /// Icon buttons on desktop
  static const double sizeTargetDesktop = 34.0;
  /// Icon buttons on phones
  static const double sizeTargetPhone = 40.0;
  /// Phone: the smallest thing a finger can tap; Android pads it to 48 with the hit area, not the drawing
  static const double sizeTargetTouch = 44.0;
  /// Phone: small buttons and pills, like Done in a sheet; the touch area stays 44
  static const double sizeControlSmall = 32.0;
  /// Phone: icon buttons, segmented controls, menu items, the toolbar, search in a sheet
  static const double sizeControlMedium = 44.0;
  /// Phone: buttons, fields, one-line rows, the dock
  static const double sizeControlLarge = 52.0;
  /// Phone: in small text and small controls: meta lines, chips, help, counts
  static const double sizeIconSmall = 16.0;
  /// Phone: in rows, fields, menus, buttons, banners
  static const double sizeIconMedium = 20.0;
  /// Phone: in bars, the toolbar, the dock and the selection bar
  static const double sizeIconLarge = 24.0;
  /// Text fields
  static const double sizeField = 40.0;
  /// Text fields and buttons on sign in
  static const double sizeFieldLarge = 44.0;
  /// Phone: text fields
  static const double sizeFieldPhone = 52.0;
  /// Tag and reminder chips
  static const double sizeChip = 27.0;
  /// Chips on cards
  static const double sizeChipCard = 22.0;
  /// Checkboxes
  static const double sizeCheckbox = 18.0;
  /// Checkboxes on cards
  static const double sizeCheckboxCard = 14.0;
  /// Toolbar buttons are a little taller than wide
  static const double sizeToolbarButtonWidth = 26.0;
  /// Toolbar buttons
  static const double sizeToolbarButtonHeight = 28.0;
  /// Square on phones
  static const double sizeToolbarButtonPhone = 40.0;
  /// Each list level
  static const double sizeListIndent = 26.0;
  /// Each list level on cards
  static const double sizeListIndentCard = 14.0;
  /// Lists go three levels deep
  static const int sizeListDepth = 3;
  /// The sidebar
  static const double sizeSidebar = 248.0;
  /// Folded to icons
  static const double sizeSidebarFolded = 64.0;
  /// The drawer on phones
  static const double sizeSidebarDrawer = 292.0;
  /// Phone: buttons in sheets, forms and docks
  static const double sizeButtonPhone = 52.0;
  /// Phone: the floating search field and the round buttons beside it
  static const double sizeDock = 52.0;
  /// Phone: the least height of a row in a grouped list; a row with a second line grows, 12 above and below
  static const double sizeRow = 52.0;
  static const double densityDefaultSpace8 = 8.0;
  static const double densityDefaultSpace12 = 12.0;
  static const double densityDefaultSpace16 = 16.0;
  static const double densityDefaultSpace24 = 24.0;
  static const double densityDefaultSpace32 = 32.0;
  static const double densityDefaultSpace48 = 48.0;
  /// Buttons, fields, one-line rows, the dock, New note and snackbars
  static const double densityDefaultControl = 52.0;
  /// The top bar under the status bar
  static const double densityDefaultBar = 52.0;
  /// Line height of note text in the editor and versions
  static const double densityDefaultNoteLineHeight = 1.7;
  static const int densityDefaultPreviewMasonry = 6;
  static const int densityDefaultPreviewGrid = 4;
  static const int densityDefaultPreviewList = 2;
  static const int densityDefaultPreviewPictures = 4;
  static const double densityCompactSpace8 = 4.0;
  static const double densityCompactSpace12 = 8.0;
  static const double densityCompactSpace16 = 12.0;
  static const double densityCompactSpace24 = 16.0;
  static const double densityCompactSpace32 = 24.0;
  static const double densityCompactSpace48 = 32.0;
  /// What is 52 at Default is 44, still a full touch area
  static const double densityCompactControl = 44.0;
  /// The top bar under the status bar, as tall as its buttons
  static const double densityCompactBar = 44.0;
  /// Line height of note text in the editor and versions
  static const double densityCompactNoteLineHeight = 1.55;
  static const int densityCompactPreviewMasonry = 4;
  static const int densityCompactPreviewGrid = 3;
  static const int densityCompactPreviewList = 1;
  static const int densityCompactPreviewPictures = 2;
  /// The page
  static const double layerBase = 0.0;
  /// A part lifted inside its own component, like the actions on a card
  static const double layerRaised = 1.0;
  /// The top bar and the save bar
  static const double layerSticky = 10.0;
  /// The selection bar and the new-note button
  static const double layerFloat = 20.0;
  /// The shade behind the phone drawer
  static const double layerScrim = 30.0;
  /// The sidebar
  static const double layerDrawer = 40.0;
  /// Dialogs and the shade behind them
  static const double layerOverlay = 50.0;
  /// Menus and pickers, also when opened from a dialog
  static const double layerPopover = 60.0;
  /// Toasts, above everything you can act on
  static const double layerToast = 70.0;
  /// Tooltips
  static const double layerTooltip = 80.0;
  /// Larger phones in landscape
  static const double breakpointSm = 640.0;
  /// Below this: the phone layout (drawer, new-note button, sheets, toolbar at the bottom)
  static const double breakpointMd = 768.0;
  /// From here: the sidebar is open and sign in shows the collage
  static const double breakpointLg = 1024.0;
  /// Wide screens
  static const double breakpointXl = 1280.0;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  /// Note title in the editor
  static const TextStyle typeNoteTitle = TextStyle(fontSize: 34.0, height: 1.12, fontWeight: FontWeight.w700, letterSpacing: -0.952);
  /// Note title on phones
  static const TextStyle typeNoteTitlePhone = TextStyle(fontSize: 27.0, height: 1.12, fontWeight: FontWeight.w700, letterSpacing: -0.756);
  /// Note text
  static const TextStyle typeBody = TextStyle(fontSize: 16.5, height: 1.7, fontWeight: FontWeight.w500, letterSpacing: 0.0);
  /// Code blocks (mono)
  static const TextStyle typeCode = TextStyle(fontSize: 13.5, height: 1.7, fontWeight: FontWeight.w400, letterSpacing: 0.0);
  /// Details under the title, save status
  static const TextStyle typeMeta = TextStyle(fontSize: 13.0, height: 1.4, fontWeight: FontWeight.w400, letterSpacing: 0.0);
  /// Tag and reminder chips
  static const TextStyle typeChip = TextStyle(fontSize: 12.5, height: 1, fontWeight: FontWeight.w500, letterSpacing: 0.0);
  /// Title on a note card
  static const TextStyle typeCardTitle = TextStyle(fontSize: 15.5, height: 1.3, fontWeight: FontWeight.w600, letterSpacing: -0.186);
  /// Text on a note card
  static const TextStyle typeCardBody = TextStyle(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w500, letterSpacing: 0.0);
  /// Uppercase group labels
  static const TextStyle typeLabel = TextStyle(fontSize: 12.0, height: 1.3, fontWeight: FontWeight.w600, letterSpacing: 0.72);
  /// Keyboard keys, day letters, the smallest labels
  static const TextStyle typeCaption = TextStyle(fontSize: 11.5, height: 1.3, fontWeight: FontWeight.w500, letterSpacing: 0.0);
  /// Card footers, hints at the foot of a panel, and the small buttons on code blocks and attachments
  static const TextStyle typeFootnote = TextStyle(fontSize: 12.0, height: 1.4, fontWeight: FontWeight.w400, letterSpacing: 0.0);
  /// Help under a field, second lines, counts
  static const TextStyle typeSmall = TextStyle(fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w400, letterSpacing: 0.0);
  /// Buttons, tabs, menu items
  static const TextStyle typeControl = TextStyle(fontSize: 13.5, height: 1.3, fontWeight: FontWeight.w500, letterSpacing: 0.0);
  /// Text in the app around the notes
  static const TextStyle typeUi = TextStyle(fontSize: 14.0, height: 1.45, fontWeight: FontWeight.w400, letterSpacing: 0.0);
  /// The line under a big title, large buttons
  static const TextStyle typeLead = TextStyle(fontSize: 15.0, height: 1.5, fontWeight: FontWeight.w400, letterSpacing: 0.0);
  /// Section titles in settings and admin
  static const TextStyle typeTitle = TextStyle(fontSize: 16.0, height: 1.35, fontWeight: FontWeight.w600, letterSpacing: -0.16);
  /// Dialog titles, empty states, the reminder summary
  static const TextStyle typeHeading = TextStyle(fontSize: 18.0, height: 1.3, fontWeight: FontWeight.w700, letterSpacing: -0.252);
  /// Page titles
  static const TextStyle typePage = TextStyle(fontSize: 23.0, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: -0.506);
  /// Page titles on phones
  static const TextStyle typePagePhone = TextStyle(fontSize: 21.0, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: -0.462);
  /// Sign in and big numbers
  static const TextStyle typeDisplay = TextStyle(fontSize: 28.0, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -0.784);
  /// Phone: a page title at the top of a list, before it collapses into the bar. Lining figures.
  static const TextStyle typeLargeTitle = TextStyle(fontSize: 28.0, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -0.28);
  /// Phone: the title in the bar once the large title has scrolled away
  static const TextStyle typeNavTitle = TextStyle(fontSize: 17.0, height: 1.3, fontWeight: FontWeight.w600, letterSpacing: -0.17);
  /// Phone: the title of a sheet
  static const TextStyle typeSheetTitle = TextStyle(fontSize: 20.0, height: 1.25, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  /// Phone: rows, buttons, fields and search
  static const TextStyle typeRow = TextStyle(fontSize: 16.0, height: 1.35, fontWeight: FontWeight.w400, letterSpacing: 0.0);
  /// Heading 1 in a note: size as a multiple of the note text
  static const double headingH1Scale = 1.55;
  static const double headingH1LineHeight = 1.22;
  static const FontWeight headingH1Weight = FontWeight.w700;
  /// Letter spacing in em
  static const double headingH1Tracking = -0.022;
  /// Heading 2: size as a multiple of the note text
  static const double headingH2Scale = 1.24;
  static const double headingH2LineHeight = 1.3;
  static const FontWeight headingH2Weight = FontWeight.w700;
  /// Letter spacing in em
  static const double headingH2Tracking = -0.012;
  /// Heading 3, in secondary text color: size as a multiple of the note text
  static const double headingH3Scale = 1.03;
  static const double headingH3LineHeight = 1.45;
  static const FontWeight headingH3Weight = FontWeight.w600;
  /// Letter spacing in em
  static const double headingH3Tracking = 0.0;
  /// A button being pressed
  static const Duration motionDurationPress = Duration(milliseconds: 100);
  /// Hover and press feedback
  static const Duration motionDurationHover = Duration(milliseconds: 150);
  /// Things fading in: menus, tooltips, the background changing color
  static const Duration motionDurationFade = Duration(milliseconds: 200);
  /// A ticked item sliding below the open ones, after a 320 ms pause
  static const Duration motionDurationSink = Duration(milliseconds: 280);
  /// The header sliding away and back while scrolling
  static const Duration motionDurationHeader = Duration(milliseconds: 300);
  /// The check mark popping in
  static const Duration motionDurationTick = Duration(milliseconds: 300);
  /// Progress bars, pictures fading in, a sheet leaving
  static const Duration motionDurationSlow = Duration(milliseconds: 300);
  /// A new highlight drawing in, line by line
  static const Duration motionDurationPaint = Duration(milliseconds: 600);
  /// Things coming in or sliding to a new place: bars, dialogs, cards, chips, the chosen option
  static const Duration motionDurationMove = Duration(milliseconds: 240);
  /// The pause before a ticked item sinks
  static const Duration motionDurationSinkDelay = Duration(milliseconds: 320);
  /// Things leaving: menus, pop-overs, dialogs, toasts and tooltips fade out faster than they came in
  static const Duration motionDurationExit = Duration(milliseconds: 140);
  /// A card growing into the open note, and shrinking back
  static const Duration motionDurationMorph = Duration(milliseconds: 380);
  /// The read-only bar shaking when you try to type
  static const Duration motionDurationNudge = Duration(milliseconds: 420);
  /// A late reminder's bell ringing once
  static const Duration motionDurationRing = Duration(milliseconds: 900);
  /// One blink of a text caret
  static const Duration motionDurationBlink = Duration(milliseconds: 1000);
  /// One turn of a spinner
  static const Duration motionDurationSpin = Duration(milliseconds: 1000);
  /// One sweep of a loading shimmer
  static const Duration motionDurationShimmer = Duration(milliseconds: 1400);
  /// A flash that says “here”: a highlight you jumped to, a person just added
  static const Duration motionDurationFlash = Duration(milliseconds: 1400);
  /// One slow sway: the floating cards on sign in, the waiting picture
  static const Duration motionDurationSway = Duration(milliseconds: 2400);
  /// Phone: how long a finger rests before a long press starts selecting
  static const Duration motionDurationLongPress = Duration(milliseconds: 420);
  /// Anything that comes in or moves
  static const Cubic motionEaseStandard = Cubic(0.2, 0.7, 0.2, 1);
  /// Rolling text and a highlight drawing in
  static const Cubic motionEaseRoll = Cubic(0.2, 0.8, 0.3, 1);
  /// Anything leaving: menus, dialogs, toasts, cards, rolling text going out
  static const Cubic motionEaseExit = Cubic(0.5, 0, 0.8, 0.4);
  /// Small things popping in: the check mark, a dialog, a toast, a new tag
  static const Cubic motionEasePop = Cubic(0.2, 0.8, 0.3, 1.3);
  /// Things that sway and settle: the floating cards, the waiting picture
  static const Cubic motionEaseInOut = Cubic(0.45, 0, 0.25, 1);
  static const Duration motionSpringSmoothDuration = Duration(milliseconds: 500);
  static const double motionSpringSmoothBounce = 0.0;
  static const Duration motionSpringSnappyDuration = Duration(milliseconds: 320);
  static const double motionSpringSnappyBounce = 0.12;
  static const Duration motionSpringPopDuration = Duration(milliseconds: 420);
  static const double motionSpringPopBounce = 0.35;
  static const Duration motionSpringKeyboardDuration = Duration(milliseconds: 380);
  static const double motionSpringKeyboardBounce = 0.0;
  /// Percent of the late red mixed into a late reminder chip
  static const double blendLateChip = 10.0;

  /// Tag colors as they are stored, by palette name.
  static const Map<String, Color> tagStored = {
    'red': Color(0xFFE57373),
    'pink': Color(0xFFF06292),
    'purple': Color(0xFFBA68C8),
    'deepPurple': Color(0xFF9575CD),
    'indigo': Color(0xFF7986CB),
    'blue': Color(0xFF64B5F6),
    'lightBlue': Color(0xFF4FC3F7),
    'cyan': Color(0xFF4DD0E1),
    'teal': Color(0xFF4DB6AC),
    'green': Color(0xFF81C784),
    'lightGreen': Color(0xFFAED581),
    'lime': Color(0xFFDCE775),
    'amber': Color(0xFFFFD54F),
    'orange': Color(0xFFFFB74D),
    'deepOrange': Color(0xFFFF8A65),
    'brown': Color(0xFFA1887F),
    'blueGrey': Color(0xFF90A4AE),
  };

  /// Highlight names in the order the pickers show them. Notes store the name.
  static const List<String> highlightNames = ['yellow', 'green', 'blue', 'pink', 'purple'];
}

@immutable
class AnchorBackground {
  const AnchorBackground({required this.id, required this.name, required this.palette, this.pattern});

  final String? id;
  final String name;
  final String palette;
  final String? pattern;
}

abstract final class AnchorBackgrounds {
  static const List<AnchorBackground> colors = [
    AnchorBackground(id: null, name: 'Default', palette: 'none'),
    AnchorBackground(id: 'color_yellow', name: 'Yellow', palette: 'yellow'),
    AnchorBackground(id: 'color_orange', name: 'Orange', palette: 'orange'),
    AnchorBackground(id: 'color_brown', name: 'Brown', palette: 'brown'),
    AnchorBackground(id: 'color_red', name: 'Red', palette: 'red'),
    AnchorBackground(id: 'color_pink', name: 'Pink', palette: 'pink'),
    AnchorBackground(id: 'color_purple', name: 'Purple', palette: 'purple'),
    AnchorBackground(id: 'color_dark_blue', name: 'Indigo', palette: 'dark_blue'),
    AnchorBackground(id: 'color_blue', name: 'Blue', palette: 'blue'),
    AnchorBackground(id: 'color_teal', name: 'Teal', palette: 'teal'),
    AnchorBackground(id: 'color_green', name: 'Green', palette: 'green'),
  ];

  static const List<AnchorBackground> patterns = [
    AnchorBackground(id: 'pattern_dots', name: 'Dots', palette: 'paper', pattern: 'dots'),
    AnchorBackground(id: 'pattern_grid', name: 'Grid', palette: 'yellow', pattern: 'grid'),
    AnchorBackground(id: 'pattern_lines', name: 'Lines', palette: 'blue', pattern: 'lines'),
    AnchorBackground(id: 'pattern_waves', name: 'Waves', palette: 'green', pattern: 'waves'),
    AnchorBackground(id: 'pattern_groceries', name: 'Groceries', palette: 'red', pattern: 'icon:shopping-bag:0'),
    AnchorBackground(id: 'pattern_music', name: 'Music', palette: 'purple', pattern: 'icon:music:0'),
    AnchorBackground(id: 'pattern_travel', name: 'Travel', palette: 'teal', pattern: 'icon:plane:28.6'),
    AnchorBackground(id: 'pattern_code', name: 'Code', palette: 'slate', pattern: 'icon:code:0'),
  ];

  /// The background a note stored, or the default for an unknown or empty id.
  static AnchorBackground of(String? id) {
    for (final b in colors) {
      if (b.id == id) return b;
    }
    for (final b in patterns) {
      if (b.id == id) return b;
    }
    return colors.first;
  }
}

@immutable
class AnchorNoteColors {
  const AnchorNoteColors({required this.bg, required this.surface, required this.border, required this.pattern, required this.muted, this.highlights = const {}});

  final Color bg;
  final Color surface;
  final Color border;
  final Color pattern;
  final Color muted;

  /// Highlight colors that differ from [AnchorColors.highlights] on this note.
  final Map<String, AnchorHighlight> highlights;

  static AnchorNoteColors lerp(AnchorNoteColors a, AnchorNoteColors b, double t) => AnchorNoteColors(
        bg: Color.lerp(a.bg, b.bg, t)!,
        surface: Color.lerp(a.surface, b.surface, t)!,
        border: Color.lerp(a.border, b.border, t)!,
        pattern: Color.lerp(a.pattern, b.pattern, t)!,
        muted: Color.lerp(a.muted, b.muted, t)!,
        highlights: t < 0.5 ? a.highlights : b.highlights,
      );
}

/// A highlight: the fill behind the text and the swatch edge.
@immutable
class AnchorHighlight {
  const AnchorHighlight({required this.fill, this.ink});

  final Color fill;
  final Color? ink;

  static AnchorHighlight lerp(AnchorHighlight a, AnchorHighlight b, double t) => AnchorHighlight(
        fill: Color.lerp(a.fill, b.fill, t)!,
        ink: Color.lerp(a.ink, b.ink, t),
      );
}

/// How a tag is drawn: its stored color, the # on a chip, and its swatch fill.
@immutable
class AnchorTagColors {
  const AnchorTagColors({required this.stored, required this.hash, required this.tintFill});

  final Color stored;
  final Color hash;
  final Color tintFill;

  static AnchorTagColors lerp(AnchorTagColors a, AnchorTagColors b, double t) => AnchorTagColors(
        stored: a.stored,
        hash: Color.lerp(a.hash, b.hash, t)!,
        tintFill: Color.lerp(a.tintFill, b.tintFill, t)!,
      );
}

Map<String, V> _lerpMap<V>(Map<String, V> a, Map<String, V> b, double t, V Function(V, V, double) f) =>
    {for (final k in a.keys) k: b.containsKey(k) ? f(a[k] as V, b[k] as V, t) : a[k] as V};

@immutable
class AnchorColors extends ThemeExtension<AnchorColors> {
  const AnchorColors({
    required this.accentStrong,
    required this.accentInk,
    required this.appPage,
    required this.appSurface,
    required this.appText,
    required this.appMuted,
    required this.appBorder,
    required this.appDivider,
    required this.appSubtle,
    required this.appSidebar,
    required this.appInverse,
    required this.appOnInverse,
    required this.appInverseLink,
    required this.appInverseDanger,
    required this.appOverlay,
    required this.appFieldLine,
    required this.checkMark,
    required this.statusDanger,
    required this.statusLate,
    required this.statusAdded,
    required this.statusRemoved,
    required this.statusAddedInk,
    required this.statusRemovedInk,
    required this.statusWarnText,
    required this.statusWarnFill,
    required this.statusOnDanger,
    required this.blendAddedLine,
    required this.blendAddedWord,
    required this.blendRemovedLine,
    required this.blendRemovedWord,
    required this.shadowRaised,
    required this.shadowFloating,
    required this.shadowMenu,
    required this.shadowLift,
    required this.shadowDialog,
    required this.shadowEdge,
    required this.shadowXs,
    required this.shadowSm,
    required this.shadowControl,
    required this.shadowKnob,
    required this.shadowBar,
    required this.shadowFab,
    required this.shadowGhost,
    required this.notes,
    required this.highlights,
    required this.tags,
  });

  /// Anything thin in orange: ticked boxes, rings, focus, the current marker, progress, drop lines
  final Color accentStrong;
  /// Orange text, such as links
  final Color accentInk;
  /// Page background
  final Color appPage;
  /// Cards, menus, dialogs and plain notes
  final Color appSurface;
  /// Text and primary buttons
  final Color appText;
  /// Secondary text and icons
  final Color appMuted;
  /// Borders of cards and menus
  final Color appBorder;
  /// Lines inside a card or list
  final Color appDivider;
  /// Muted fills and hover
  final Color appSubtle;
  /// The sidebar, beside the page
  final Color appSidebar;
  /// The selection bar, save bar and toasts
  final Color appInverse;
  /// Text on those
  final Color appOnInverse;
  /// Undo on a toast
  final Color appInverseLink;
  /// The icon and time line on an error toast
  final Color appInverseDanger;
  /// Behind dialogs and the phone drawer
  final Color appOverlay;
  /// Text field borders, 3 : 1 on the page
  final Color appFieldLine;
  /// The tick inside a ticked box
  final Color checkMark;
  /// Delete buttons, errors, failed uploads
  final Color statusDanger;
  /// A reminder that has passed
  final Color statusLate;
  /// Added text in history (mixed into the note color)
  final Color statusAdded;
  /// Removed text in history (mixed into the note color)
  final Color statusRemoved;
  /// The + sign and bar
  final Color statusAddedInk;
  /// The − sign and bar
  final Color statusRemovedInk;
  /// Warning labels, like “Not saved”
  final Color statusWarnText;
  /// Behind warning labels
  final Color statusWarnFill;
  /// Text on a red button
  final Color statusOnDanger;
  /// Percent of green behind an added line
  final double blendAddedLine;
  /// Percent of green behind an added word
  final double blendAddedWord;
  /// Percent of red behind a removed line
  final double blendRemovedLine;
  /// Percent of red behind a removed word
  final double blendRemovedWord;
  /// Notes and cards
  final List<BoxShadow> shadowRaised;
  /// Floating bars on a note
  final List<BoxShadow> shadowFloating;
  /// Menus and pop-overs
  final List<BoxShadow> shadowMenu;
  /// A card being hovered or dragged
  final List<BoxShadow> shadowLift;
  /// Dialogs
  final List<BoxShadow> shadowDialog;
  /// A hairline around the logo and pictures
  final List<BoxShadow> shadowEdge;
  /// A control that sits a little above its row
  final List<BoxShadow> shadowXs;
  /// Small buttons over a picture or card
  final List<BoxShadow> shadowSm;
  /// The dark New note button
  final List<BoxShadow> shadowControl;
  /// The knob of a switch
  final List<BoxShadow> shadowKnob;
  /// The selection bar, save bar and toasts
  final List<BoxShadow> shadowBar;
  /// The new-note button on phones
  final List<BoxShadow> shadowFab;
  /// The small picture that follows the pointer while dragging
  final List<BoxShadow> shadowGhost;

  /// Note colors by palette name; [AnchorBackgrounds] says which background
  /// uses which.
  final Map<String, AnchorNoteColors> notes;

  /// Highlight colors by name. A note can override them in [AnchorNoteColors.highlights].
  final Map<String, AnchorHighlight> highlights;

  /// Tag colors by palette name.
  final Map<String, AnchorTagColors> tags;

  /// The highlight to draw for [color] on the note palette [note].
  AnchorHighlight highlightOn(String note, String color) => notes[note]?.highlights[color] ?? highlights[color]!;

  static const light = AnchorColors(
    accentStrong: Color(0xFFCC5F2D),
    accentInk: Color(0xFFA44004),
    appPage: Color(0xFFF0F4F8),
    appSurface: Color(0xFFFFFFFF),
    appText: Color(0xFF12141A),
    appMuted: Color(0xFF3A3C42),
    appBorder: Color(0xFFD8DEE6),
    appDivider: Color(0xFFE6EBF1),
    appSubtle: Color(0xFFE8ECF1),
    appSidebar: Color(0xFFE9EEF3),
    appInverse: Color(0xFF2D3142),
    appOnInverse: Color(0xFFF5F6F8),
    appInverseLink: Color(0xFFF39A70),
    appInverseDanger: Color(0xFFFF8F85),
    appOverlay: Color(0x5C1C1F2A),
    appFieldLine: Color(0xFF788497),
    checkMark: Color(0xFFFFFFFF),
    statusDanger: Color(0xFFC0392B),
    statusLate: Color(0xFFA61E14),
    statusAdded: Color(0xFF1F9D55),
    statusRemoved: Color(0xFFD03A4F),
    statusAddedInk: Color(0xFF166F44),
    statusRemovedInk: Color(0xFFB02237),
    statusWarnText: Color(0xFF8A4B08),
    statusWarnFill: Color(0xFFFDECC8),
    statusOnDanger: Color(0xFFFFFFFF),
    blendAddedLine: 14.0,
    blendAddedWord: 30.0,
    blendRemovedLine: 16.0,
    blendRemovedWord: 26.0,
    shadowRaised: [BoxShadow(color: Color(0x0F2D3142), offset: Offset(0.0, 8.0), blurRadius: 24.0, spreadRadius: 0.0), BoxShadow(color: Color(0x0D2D3142), offset: Offset(0.0, 1.0), blurRadius: 2.0, spreadRadius: 0.0)],
    shadowFloating: [BoxShadow(color: Color(0x24000000), offset: Offset(0.0, 8.0), blurRadius: 22.0, spreadRadius: 0.0)],
    shadowMenu: [BoxShadow(color: Color(0x242D3142), offset: Offset(0.0, 16.0), blurRadius: 32.0, spreadRadius: -8.0), BoxShadow(color: Color(0x1A2D3142), offset: Offset(0.0, 4.0), blurRadius: 10.0, spreadRadius: -2.0), BoxShadow(color: Color(0x0F2D3142), offset: Offset(0.0, 1.0), blurRadius: 2.0, spreadRadius: 0.0)],
    shadowLift: [BoxShadow(color: Color(0x0D000000), offset: Offset(0.0, 2.0), blurRadius: 6.0, spreadRadius: 0.0), BoxShadow(color: Color(0x33000000), offset: Offset(0.0, 14.0), blurRadius: 30.0, spreadRadius: -10.0)],
    shadowDialog: [BoxShadow(color: Color(0x471C1F2A), offset: Offset(0.0, 32.0), blurRadius: 64.0, spreadRadius: -16.0), BoxShadow(color: Color(0x1F1C1F2A), offset: Offset(0.0, 12.0), blurRadius: 24.0, spreadRadius: -6.0), BoxShadow(color: Color(0x0F1C1F2A), offset: Offset(0.0, 2.0), blurRadius: 4.0, spreadRadius: 0.0)],
    shadowEdge: [BoxShadow(color: Color(0x0F000000), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 1.0)],
    shadowXs: [BoxShadow(color: Color(0x0F000000), offset: Offset(0.0, 1.0), blurRadius: 2.0, spreadRadius: 0.0)],
    shadowSm: [BoxShadow(color: Color(0x14000000), offset: Offset(0.0, 2.0), blurRadius: 6.0, spreadRadius: 0.0)],
    shadowControl: [BoxShadow(color: Color(0x66000000), offset: Offset(0.0, 6.0), blurRadius: 14.0, spreadRadius: -8.0), BoxShadow(color: Color(0x1A000000), offset: Offset(0.0, 1.0), blurRadius: 2.0, spreadRadius: 0.0)],
    shadowKnob: [BoxShadow(color: Color(0x47000000), offset: Offset(0.0, 1.0), blurRadius: 3.0, spreadRadius: 0.0)],
    shadowBar: [BoxShadow(color: Color(0x80000000), offset: Offset(0.0, 18.0), blurRadius: 40.0, spreadRadius: -14.0)],
    shadowFab: [BoxShadow(color: Color(0x1F000000), offset: Offset(0.0, 2.0), blurRadius: 6.0, spreadRadius: 0.0), BoxShadow(color: Color(0x73000000), offset: Offset(0.0, 10.0), blurRadius: 24.0, spreadRadius: -8.0)],
    shadowGhost: [BoxShadow(color: Color(0x1F000000), offset: Offset(0.0, 2.0), blurRadius: 5.0, spreadRadius: 0.0), BoxShadow(color: Color(0x38000000), offset: Offset(0.0, 6.0), blurRadius: 18.0, spreadRadius: 0.0)],
    notes: {
      'paper': AnchorNoteColors(bg: Color(0xFFEEF0F3), surface: Color(0xFFDDE6EF), border: Color(0xFFCAD4DF), pattern: Color(0xFFD6E3F1), muted: Color(0xFF3A3C41)),
      'slate': AnchorNoteColors(bg: Color(0xFFE9F2F7), surface: Color(0xFFD6E8F3), border: Color(0xFFC2D6E2), pattern: Color(0xFFCEE5F4), muted: Color(0xFF393C42)),
      'red': AnchorNoteColors(bg: Color(0xFFFFE8E4), surface: Color(0xFFFFD9D5), border: Color(0xFFF2C7C2), pattern: Color(0xFFFFD4CF), muted: Color(0xFF3D3A3E)),
      'orange': AnchorNoteColors(bg: Color(0xFFFFEAD6), surface: Color(0xFFFFDDC3), border: Color(0xFFEFCAB0), pattern: Color(0xFFFFD8BB), muted: Color(0xFF3D3B3C)),
      'yellow': AnchorNoteColors(bg: Color(0xFFFFF3CA), surface: Color(0xFFF8E7B5), border: Color(0xFFE6D5A1), pattern: Color(0xFFF6E4AC), muted: Color(0xFF3D3C3A)),
      'green': AnchorNoteColors(bg: Color(0xFFE0F7E4), surface: Color(0xFFCFEED4), border: Color(0xFFBCDCC2), pattern: Color(0xFFC8ECCE), muted: Color(0xFF373D3E)),
      'teal': AnchorNoteColors(bg: Color(0xFFDAF7F6), surface: Color(0xFFC5EEED), border: Color(0xFFB1DCDC), pattern: Color(0xFFBCECEB), muted: Color(0xFF363D42)),
      'blue': AnchorNoteColors(bg: Color(0xFFE0F3FF), surface: Color(0xFFCEE8FF), border: Color(0xFFBBD6EF), pattern: Color(0xFFC7E6FF), muted: Color(0xFF373C43)),
      'dark_blue': AnchorNoteColors(bg: Color(0xFFECEEFF), surface: Color(0xFFDEE2FF), border: Color(0xFFCCD0F0), pattern: Color(0xFFDADEFF), muted: Color(0xFF393B43)),
      'purple': AnchorNoteColors(bg: Color(0xFFFAEAFD), surface: Color(0xFFF2DCF6), border: Color(0xFFE0CAE5), pattern: Color(0xFFF1D7F6), muted: Color(0xFF3C3B43), highlights: {'purple': AnchorHighlight(fill: Color(0xFFE7C4FF))}),
      'pink': AnchorNoteColors(bg: Color(0xFFFFE8F3), surface: Color(0xFFFCDAE8), border: Color(0xFFEBC7D7), pattern: Color(0xFFFCD4E6), muted: Color(0xFF3D3A41)),
      'brown': AnchorNoteColors(bg: Color(0xFFFAEDE5), surface: Color(0xFFF5E0D2), border: Color(0xFFE5CDBF), pattern: Color(0xFFF6DBCA), muted: Color(0xFF3C3B3F)),
      'none': AnchorNoteColors(bg: Color(0xFFFFFFFF), surface: Color(0xFFF0F4F7), border: Color(0xFFD8DFE6), pattern: Color(0xFFFFFFFF), muted: Color(0xFF3D3E43)),
    },
    highlights: {
      'yellow': AnchorHighlight(fill: Color(0xFFFEEA74), ink: Color(0xFF90800F)),
      'green': AnchorHighlight(fill: Color(0xFFAAF5B9), ink: Color(0xFF009343)),
      'blue': AnchorHighlight(fill: Color(0xFFAAE6FF), ink: Color(0xFF0D8AAF)),
      'pink': AnchorHighlight(fill: Color(0xFFFFC4E1), ink: Color(0xFFD7469C)),
      'purple': AnchorHighlight(fill: Color(0xFFECCFFF), ink: Color(0xFFAD59DB)),
    },
    tags: {
      'red': AnchorTagColors(stored: Color(0xFFE57373), hash: Color(0xFFC05254), tintFill: Color(0xFFFFDBD9)),
      'pink': AnchorTagColors(stored: Color(0xFFF06292), hash: Color(0xFFCA3E72), tintFill: Color(0xFFFFDBE5)),
      'purple': AnchorTagColors(stored: Color(0xFFBA68C8), hash: Color(0xFFA554B3), tintFill: Color(0xFFF8DEFC)),
      'deepPurple': AnchorTagColors(stored: Color(0xFF9575CD), hash: Color(0xFF8666BD), tintFill: Color(0xFFECE1FF)),
      'indigo': AnchorTagColors(stored: Color(0xFF7986CB), hash: Color(0xFF6874BB), tintFill: Color(0xFFDEE6FF)),
      'blue': AnchorTagColors(stored: Color(0xFF64B5F6), hash: Color(0xFF2C80BE), tintFill: Color(0xFFCDECFF)),
      'lightBlue': AnchorTagColors(stored: Color(0xFF4FC3F7), hash: Color(0xFF0086B7), tintFill: Color(0xFFC7EFFF)),
      'cyan': AnchorTagColors(stored: Color(0xFF4DD0E1), hash: Color(0xFF008C9D), tintFill: Color(0xFFC2F2F9)),
      'teal': AnchorTagColors(stored: Color(0xFF4DB6AC), hash: Color(0xFF008F85), tintFill: Color(0xFFC3F3ED)),
      'green': AnchorTagColors(stored: Color(0xFF81C784), hash: Color(0xFF488C4D), tintFill: Color(0xFFD4F1D4)),
      'lightGreen': AnchorTagColors(stored: Color(0xFFAED581), hash: Color(0xFF648735), tintFill: Color(0xFFDEEFCC)),
      'lime': AnchorTagColors(stored: Color(0xFFDCE775), hash: Color(0xFF7B8200), tintFill: Color(0xFFE7ECC6)),
      'amber': AnchorTagColors(stored: Color(0xFFFFD54F), hash: Color(0xFF9C7400), tintFill: Color(0xFFF4E7C3)),
      'orange': AnchorTagColors(stored: Color(0xFFFFB74D), hash: Color(0xFFAC6900), tintFill: Color(0xFFFDE4C4)),
      'deepOrange': AnchorTagColors(stored: Color(0xFFFF8A65), hash: Color(0xFFC2532F), tintFill: Color(0xFFFFDDD0)),
      'brown': AnchorTagColors(stored: Color(0xFFA1887F), hash: Color(0xFF937165), tintFill: Color(0xFFFDE1D7)),
      'blueGrey': AnchorTagColors(stored: Color(0xFF90A4AE), hash: Color(0xFF647F8C), tintFill: Color(0xFFD7ECF6)),
    },
  );

  static const dark = AnchorColors(
    accentStrong: Color(0xFFEF8354),
    accentInk: Color(0xFFFE976C),
    appPage: Color(0xFF111214),
    appSurface: Color(0xFF1C1D21),
    appText: Color(0xFFF7F7F7),
    appMuted: Color(0xFFCECECE),
    appBorder: Color(0xFF34353A),
    appDivider: Color(0xFF26272C),
    appSubtle: Color(0xFF26272C),
    appSidebar: Color(0xFF0A0B0C),
    appInverse: Color(0xFFE4E6EB),
    appOnInverse: Color(0xFF111214),
    appInverseLink: Color(0xFFA8440F),
    appInverseDanger: Color(0xFFB3261E),
    appOverlay: Color(0x9906070A),
    appFieldLine: Color(0xFF6B7482),
    checkMark: Color(0xFF1C1D21),
    statusDanger: Color(0xFFFF8A80),
    statusLate: Color(0xFFFF9D94),
    statusAdded: Color(0xFF3FCF8E),
    statusRemoved: Color(0xFFFF6B81),
    statusAddedInk: Color(0xFF6FE3A8),
    statusRemovedInk: Color(0xFFFF9AA9),
    statusWarnText: Color(0xFFFCD49A),
    statusWarnFill: Color(0xFF4A3413),
    statusOnDanger: Color(0xFF111214),
    blendAddedLine: 14.0,
    blendAddedWord: 26.0,
    blendRemovedLine: 16.0,
    blendRemovedWord: 26.0,
    shadowRaised: [BoxShadow(color: Color(0x40000000), offset: Offset(0.0, 8.0), blurRadius: 24.0, spreadRadius: 0.0), BoxShadow(color: Color(0x4D000000), offset: Offset(0.0, 1.0), blurRadius: 2.0, spreadRadius: 0.0)],
    shadowFloating: [BoxShadow(color: Color(0x24000000), offset: Offset(0.0, 8.0), blurRadius: 22.0, spreadRadius: 0.0)],
    shadowMenu: [BoxShadow(color: Color(0x73000000), offset: Offset(0.0, 22.0), blurRadius: 44.0, spreadRadius: -12.0), BoxShadow(color: Color(0x59000000), offset: Offset(0.0, 8.0), blurRadius: 18.0, spreadRadius: -4.0), BoxShadow(color: Color(0x59000000), offset: Offset(0.0, 1.0), blurRadius: 2.0, spreadRadius: 0.0)],
    shadowLift: [BoxShadow(color: Color(0x99000000), offset: Offset(0.0, 16.0), blurRadius: 32.0, spreadRadius: -10.0)],
    shadowDialog: [BoxShadow(color: Color(0xB3000000), offset: Offset(0.0, 32.0), blurRadius: 70.0, spreadRadius: -18.0), BoxShadow(color: Color(0x66000000), offset: Offset(0.0, 2.0), blurRadius: 6.0, spreadRadius: 0.0), BoxShadow(color: Color(0x0DFFFFFF), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 1.0)],
    shadowEdge: [BoxShadow(color: Color(0x0FFFFFFF), offset: Offset(0.0, 0.0), blurRadius: 0.0, spreadRadius: 1.0)],
    shadowXs: [BoxShadow(color: Color(0x4D000000), offset: Offset(0.0, 1.0), blurRadius: 2.0, spreadRadius: 0.0)],
    shadowSm: [BoxShadow(color: Color(0x4D000000), offset: Offset(0.0, 2.0), blurRadius: 6.0, spreadRadius: 0.0)],
    shadowControl: [BoxShadow(color: Color(0x99000000), offset: Offset(0.0, 6.0), blurRadius: 14.0, spreadRadius: -8.0), BoxShadow(color: Color(0x4D000000), offset: Offset(0.0, 1.0), blurRadius: 2.0, spreadRadius: 0.0)],
    shadowKnob: [BoxShadow(color: Color(0x47000000), offset: Offset(0.0, 1.0), blurRadius: 3.0, spreadRadius: 0.0)],
    shadowBar: [BoxShadow(color: Color(0xB3000000), offset: Offset(0.0, 18.0), blurRadius: 40.0, spreadRadius: -14.0)],
    shadowFab: [BoxShadow(color: Color(0x4D000000), offset: Offset(0.0, 2.0), blurRadius: 6.0, spreadRadius: 0.0), BoxShadow(color: Color(0xB3000000), offset: Offset(0.0, 10.0), blurRadius: 24.0, spreadRadius: -8.0)],
    shadowGhost: [BoxShadow(color: Color(0x1F000000), offset: Offset(0.0, 2.0), blurRadius: 5.0, spreadRadius: 0.0), BoxShadow(color: Color(0x38000000), offset: Offset(0.0, 6.0), blurRadius: 18.0, spreadRadius: 0.0)],
    notes: {
      'paper': AnchorNoteColors(bg: Color(0xFF282C30), surface: Color(0xFF33393F), border: Color(0xFF44484C), pattern: Color(0xFF39424C), muted: Color(0xFFD2D2D3)),
      'slate': AnchorNoteColors(bg: Color(0xFF212D35), surface: Color(0xFF2A3A44), border: Color(0xFF3C4A52), pattern: Color(0xFF2F4451), muted: Color(0xFFD0D3D4)),
      'red': AnchorNoteColors(bg: Color(0xFF431F1D), surface: Color(0xFF532B28), border: Color(0xFF623C39), pattern: Color(0xFF60322F), muted: Color(0xFFD7D0D0)),
      'orange': AnchorNoteColors(bg: Color(0xFF3F240C), surface: Color(0xFF4F2F16), border: Color(0xFF5E4029), pattern: Color(0xFF5B371A), muted: Color(0xFFD6D1CD)),
      'yellow': AnchorNoteColors(bg: Color(0xFF372904), surface: Color(0xFF45360D), border: Color(0xFF544623), pattern: Color(0xFF503F0F), muted: Color(0xFFD4D2CB)),
      'green': AnchorNoteColors(bg: Color(0xFF17321E), surface: Color(0xFF224028), border: Color(0xFF344F39), pattern: Color(0xFF274A2F), muted: Color(0xFFCFD4D0)),
      'teal': AnchorNoteColors(bg: Color(0xFF083232), surface: Color(0xFF114040), border: Color(0xFF294F4F), pattern: Color(0xFF124A4A), muted: Color(0xFFCCD4D4)),
      'blue': AnchorNoteColors(bg: Color(0xFF102E45), surface: Color(0xFF1A3B55), border: Color(0xFF2D4B64), pattern: Color(0xFF1F4462), muted: Color(0xFFCDD3D7)),
      'dark_blue': AnchorNoteColors(bg: Color(0xFF262748), surface: Color(0xFF323459), border: Color(0xFF414468), pattern: Color(0xFF3A3C66), muted: Color(0xFFD1D2D8)),
      'purple': AnchorNoteColors(bg: Color(0xFF37223C), surface: Color(0xFF462D4B), border: Color(0xFF553E5A), pattern: Color(0xFF513557), muted: Color(0xFFD4D1D5), highlights: {'purple': AnchorHighlight(fill: Color(0xFF7850A1))}),
      'pink': AnchorNoteColors(bg: Color(0xFF3F1F2F), surface: Color(0xFF4F2A3C), border: Color(0xFF5E3B4C), pattern: Color(0xFF5B3146), muted: Color(0xFFD6D0D3)),
      'brown': AnchorNoteColors(bg: Color(0xFF352820), surface: Color(0xFF44342A), border: Color(0xFF52453C), pattern: Color(0xFF503C2F), muted: Color(0xFFD4D2D0)),
      'none': AnchorNoteColors(bg: Color(0xFF111214), surface: Color(0xFF1C1D21), border: Color(0xFF34353A), pattern: Color(0xFF111214), muted: Color(0xFFCECECE)),
    },
    highlights: {
      'yellow': AnchorHighlight(fill: Color(0xFF805C03), ink: Color(0xFFB18001)),
      'green': AnchorHighlight(fill: Color(0xFF047239), ink: Color(0xFF039E51)),
      'blue': AnchorHighlight(fill: Color(0xFF0A6899), ink: Color(0xFF0293D8)),
      'pink': AnchorHighlight(fill: Color(0xFF9F436B), ink: Color(0xFFE34991)),
      'purple': AnchorHighlight(fill: Color(0xFF7850A1), ink: Color(0xFFA863EA)),
    },
    tags: {
      'red': AnchorTagColors(stored: Color(0xFFE57373), hash: Color(0xFFFF908F), tintFill: Color(0xFF5C3232)),
      'pink': AnchorTagColors(stored: Color(0xFFF06292), hash: Color(0xFFFF80AE), tintFill: Color(0xFF5A323D)),
      'purple': AnchorTagColors(stored: Color(0xFFBA68C8), hash: Color(0xFFE792F5), tintFill: Color(0xFF4E3553)),
      'deepPurple': AnchorTagColors(stored: Color(0xFF9575CD), hash: Color(0xFFC4A4FF), tintFill: Color(0xFF44385B)),
      'indigo': AnchorTagColors(stored: Color(0xFF7986CB), hash: Color(0xFFA4B2FB), tintFill: Color(0xFF363D5F)),
      'blue': AnchorTagColors(stored: Color(0xFF64B5F6), hash: Color(0xFF6EBFFF), tintFill: Color(0xFF22435D)),
      'lightBlue': AnchorTagColors(stored: Color(0xFF4FC3F7), hash: Color(0xFF52C5FA), tintFill: Color(0xFF18455A)),
      'cyan': AnchorTagColors(stored: Color(0xFF4DD0E1), hash: Color(0xFF48CCDD), tintFill: Color(0xFF094850)),
      'teal': AnchorTagColors(stored: Color(0xFF4DB6AC), hash: Color(0xFF62CCC2), tintFill: Color(0xFF0B4A45)),
      'green': AnchorTagColors(stored: Color(0xFF81C784), hash: Color(0xFF85CC88), tintFill: Color(0xFF2A482C)),
      'lightGreen': AnchorTagColors(stored: Color(0xFFAED581), hash: Color(0xFFA0C673), tintFill: Color(0xFF364622)),
      'lime': AnchorTagColors(stored: Color(0xFFDCE775), hash: Color(0xFFB7C14E), tintFill: Color(0xFF3F431B)),
      'amber': AnchorTagColors(stored: Color(0xFFFFD54F), hash: Color(0xFFDCB21D), tintFill: Color(0xFF4B3E16)),
      'orange': AnchorTagColors(stored: Color(0xFFFFB74D), hash: Color(0xFFEEA73A), tintFill: Color(0xFF533A18)),
      'deepOrange': AnchorTagColors(stored: Color(0xFFFF8A65), hash: Color(0xFFFF926D), tintFill: Color(0xFF5B3428)),
      'brown': AnchorTagColors(stored: Color(0xFFA1887F), hash: Color(0xFFD3AEA1), tintFill: Color(0xFF4F3A32)),
      'blueGrey': AnchorTagColors(stored: Color(0xFF90A4AE), hash: Color(0xFFA0BDCB), tintFill: Color(0xFF31434B)),
    },
  );

  @override
  AnchorColors copyWith({
    Color? accentStrong,
    Color? accentInk,
    Color? appPage,
    Color? appSurface,
    Color? appText,
    Color? appMuted,
    Color? appBorder,
    Color? appDivider,
    Color? appSubtle,
    Color? appSidebar,
    Color? appInverse,
    Color? appOnInverse,
    Color? appInverseLink,
    Color? appInverseDanger,
    Color? appOverlay,
    Color? appFieldLine,
    Color? checkMark,
    Color? statusDanger,
    Color? statusLate,
    Color? statusAdded,
    Color? statusRemoved,
    Color? statusAddedInk,
    Color? statusRemovedInk,
    Color? statusWarnText,
    Color? statusWarnFill,
    Color? statusOnDanger,
    double? blendAddedLine,
    double? blendAddedWord,
    double? blendRemovedLine,
    double? blendRemovedWord,
    List<BoxShadow>? shadowRaised,
    List<BoxShadow>? shadowFloating,
    List<BoxShadow>? shadowMenu,
    List<BoxShadow>? shadowLift,
    List<BoxShadow>? shadowDialog,
    List<BoxShadow>? shadowEdge,
    List<BoxShadow>? shadowXs,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowControl,
    List<BoxShadow>? shadowKnob,
    List<BoxShadow>? shadowBar,
    List<BoxShadow>? shadowFab,
    List<BoxShadow>? shadowGhost,
    Map<String, AnchorNoteColors>? notes,
    Map<String, AnchorHighlight>? highlights,
    Map<String, AnchorTagColors>? tags,
  }) =>
      AnchorColors(
        accentStrong: accentStrong ?? this.accentStrong,
        accentInk: accentInk ?? this.accentInk,
        appPage: appPage ?? this.appPage,
        appSurface: appSurface ?? this.appSurface,
        appText: appText ?? this.appText,
        appMuted: appMuted ?? this.appMuted,
        appBorder: appBorder ?? this.appBorder,
        appDivider: appDivider ?? this.appDivider,
        appSubtle: appSubtle ?? this.appSubtle,
        appSidebar: appSidebar ?? this.appSidebar,
        appInverse: appInverse ?? this.appInverse,
        appOnInverse: appOnInverse ?? this.appOnInverse,
        appInverseLink: appInverseLink ?? this.appInverseLink,
        appInverseDanger: appInverseDanger ?? this.appInverseDanger,
        appOverlay: appOverlay ?? this.appOverlay,
        appFieldLine: appFieldLine ?? this.appFieldLine,
        checkMark: checkMark ?? this.checkMark,
        statusDanger: statusDanger ?? this.statusDanger,
        statusLate: statusLate ?? this.statusLate,
        statusAdded: statusAdded ?? this.statusAdded,
        statusRemoved: statusRemoved ?? this.statusRemoved,
        statusAddedInk: statusAddedInk ?? this.statusAddedInk,
        statusRemovedInk: statusRemovedInk ?? this.statusRemovedInk,
        statusWarnText: statusWarnText ?? this.statusWarnText,
        statusWarnFill: statusWarnFill ?? this.statusWarnFill,
        statusOnDanger: statusOnDanger ?? this.statusOnDanger,
        blendAddedLine: blendAddedLine ?? this.blendAddedLine,
        blendAddedWord: blendAddedWord ?? this.blendAddedWord,
        blendRemovedLine: blendRemovedLine ?? this.blendRemovedLine,
        blendRemovedWord: blendRemovedWord ?? this.blendRemovedWord,
        shadowRaised: shadowRaised ?? this.shadowRaised,
        shadowFloating: shadowFloating ?? this.shadowFloating,
        shadowMenu: shadowMenu ?? this.shadowMenu,
        shadowLift: shadowLift ?? this.shadowLift,
        shadowDialog: shadowDialog ?? this.shadowDialog,
        shadowEdge: shadowEdge ?? this.shadowEdge,
        shadowXs: shadowXs ?? this.shadowXs,
        shadowSm: shadowSm ?? this.shadowSm,
        shadowControl: shadowControl ?? this.shadowControl,
        shadowKnob: shadowKnob ?? this.shadowKnob,
        shadowBar: shadowBar ?? this.shadowBar,
        shadowFab: shadowFab ?? this.shadowFab,
        shadowGhost: shadowGhost ?? this.shadowGhost,
        notes: notes ?? this.notes,
        highlights: highlights ?? this.highlights,
        tags: tags ?? this.tags,
      );

  @override
  AnchorColors lerp(ThemeExtension<AnchorColors>? other, double t) {
    if (other is! AnchorColors) return this;
    return AnchorColors(
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      appPage: Color.lerp(appPage, other.appPage, t)!,
      appSurface: Color.lerp(appSurface, other.appSurface, t)!,
      appText: Color.lerp(appText, other.appText, t)!,
      appMuted: Color.lerp(appMuted, other.appMuted, t)!,
      appBorder: Color.lerp(appBorder, other.appBorder, t)!,
      appDivider: Color.lerp(appDivider, other.appDivider, t)!,
      appSubtle: Color.lerp(appSubtle, other.appSubtle, t)!,
      appSidebar: Color.lerp(appSidebar, other.appSidebar, t)!,
      appInverse: Color.lerp(appInverse, other.appInverse, t)!,
      appOnInverse: Color.lerp(appOnInverse, other.appOnInverse, t)!,
      appInverseLink: Color.lerp(appInverseLink, other.appInverseLink, t)!,
      appInverseDanger: Color.lerp(appInverseDanger, other.appInverseDanger, t)!,
      appOverlay: Color.lerp(appOverlay, other.appOverlay, t)!,
      appFieldLine: Color.lerp(appFieldLine, other.appFieldLine, t)!,
      checkMark: Color.lerp(checkMark, other.checkMark, t)!,
      statusDanger: Color.lerp(statusDanger, other.statusDanger, t)!,
      statusLate: Color.lerp(statusLate, other.statusLate, t)!,
      statusAdded: Color.lerp(statusAdded, other.statusAdded, t)!,
      statusRemoved: Color.lerp(statusRemoved, other.statusRemoved, t)!,
      statusAddedInk: Color.lerp(statusAddedInk, other.statusAddedInk, t)!,
      statusRemovedInk: Color.lerp(statusRemovedInk, other.statusRemovedInk, t)!,
      statusWarnText: Color.lerp(statusWarnText, other.statusWarnText, t)!,
      statusWarnFill: Color.lerp(statusWarnFill, other.statusWarnFill, t)!,
      statusOnDanger: Color.lerp(statusOnDanger, other.statusOnDanger, t)!,
      blendAddedLine: lerpDouble(blendAddedLine, other.blendAddedLine, t)!,
      blendAddedWord: lerpDouble(blendAddedWord, other.blendAddedWord, t)!,
      blendRemovedLine: lerpDouble(blendRemovedLine, other.blendRemovedLine, t)!,
      blendRemovedWord: lerpDouble(blendRemovedWord, other.blendRemovedWord, t)!,
      shadowRaised: BoxShadow.lerpList(shadowRaised, other.shadowRaised, t)!,
      shadowFloating: BoxShadow.lerpList(shadowFloating, other.shadowFloating, t)!,
      shadowMenu: BoxShadow.lerpList(shadowMenu, other.shadowMenu, t)!,
      shadowLift: BoxShadow.lerpList(shadowLift, other.shadowLift, t)!,
      shadowDialog: BoxShadow.lerpList(shadowDialog, other.shadowDialog, t)!,
      shadowEdge: BoxShadow.lerpList(shadowEdge, other.shadowEdge, t)!,
      shadowXs: BoxShadow.lerpList(shadowXs, other.shadowXs, t)!,
      shadowSm: BoxShadow.lerpList(shadowSm, other.shadowSm, t)!,
      shadowControl: BoxShadow.lerpList(shadowControl, other.shadowControl, t)!,
      shadowKnob: BoxShadow.lerpList(shadowKnob, other.shadowKnob, t)!,
      shadowBar: BoxShadow.lerpList(shadowBar, other.shadowBar, t)!,
      shadowFab: BoxShadow.lerpList(shadowFab, other.shadowFab, t)!,
      shadowGhost: BoxShadow.lerpList(shadowGhost, other.shadowGhost, t)!,
      notes: _lerpMap(notes, other.notes, t, AnchorNoteColors.lerp),
      highlights: _lerpMap(highlights, other.highlights, t, AnchorHighlight.lerp),
      tags: _lerpMap(tags, other.tags, t, AnchorTagColors.lerp),
    );
  }
}
