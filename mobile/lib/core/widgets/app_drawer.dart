import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/tags/domain/tag.dart';
import '../../features/tags/presentation/tags_controller.dart';
import 'anchor_icon.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer>
    with SingleTickerProviderStateMixin {
  bool _tagsExpanded = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    // Start animation immediately but don't block on it
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tagsAsync = ref.watch(tagsControllerProvider);
    final selectedTagId = ref.watch(selectedTagFilterProvider);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1C1E26), const Color(0xFF262A36)]
                  : [const Color(0xFFF8F9FC), const Color(0xFFEEF1F8)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header with branding
                _buildHeader(theme, isDark),

                const SizedBox(height: 8),

                // Main navigation
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primary Navigation
                        _buildNavItem(
                          icon: LucideIcons.fileText,
                          label: 'All Notes',
                          isSelected: selectedTagId == null,
                          onTap: () {
                            ref
                                .read(selectedTagFilterProvider.notifier)
                                .clear();
                            Navigator.pop(context);
                          },
                          theme: theme,
                        ),

                        _buildNavItem(
                          icon: LucideIcons.archive,
                          label: 'Archive',
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/archive');
                          },
                          theme: theme,
                        ),

                        _buildNavItem(
                          icon: LucideIcons.trash2,
                          label: 'Trash',
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/trash');
                          },
                          theme: theme,
                        ),

                        const SizedBox(height: 16),

                        // Tags Section
                        _buildTagsSection(
                          theme: theme,
                          tagsAsync: tagsAsync,
                          selectedTagId: selectedTagId,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom section with settings
                _buildBottomSection(theme, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          const SizedBox(width: 52, height: 52, child: AnchorIcon(size: 48)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anchor',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Your thoughts, secured',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isSelected = false,
    bool enabled = true,
    Color? activeColor,
    Widget? trailing,
  }) {
    final color = activeColor ?? theme.colorScheme.primary;

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: color.withValues(alpha: 0.2), width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? color
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? color
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.85,
                              ),
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection({
    required ThemeData theme,
    required AsyncValue<List<Tag>> tagsAsync,
    required String? selectedTagId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags header with expand/collapse
        InkWell(
          onTap: () => setState(() => _tagsExpanded = !_tagsExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 4),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _tagsExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'TAGS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    LucideIcons.plus,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  onPressed: () => _showCreateTagSheet(),
                  tooltip: 'New tag',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tags list
        AnimatedCrossFade(
          firstChild: tagsAsync.when(
            data: (tags) {
              if (tags.isEmpty) {
                return _buildEmptyTagsState(theme);
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final isSelected = selectedTagId == tag.id;
                  final tagColor = parseTagColor(
                    tag.color,
                    fallback: theme.colorScheme.primary,
                  );
                  return _TagItemWidget(
                    tag: tag,
                    isSelected: isSelected,
                    tagColor: tagColor,
                    theme: theme,
                    onTap: () {
                      ref
                          .read(selectedTagFilterProvider.notifier)
                          .select(tag.id);
                      Navigator.pop(context);
                    },
                    onLongPress: () => _showTagOptionsSheet(tag),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _tagsExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildEmptyTagsState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.tags,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Create tags to organize your notes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: _buildNavItem(
        icon: LucideIcons.settings,
        label: 'Settings',
        onTap: () {
          Navigator.pop(context);
          context.push('/settings');
        },
        theme: theme,
      ),
    );
  }

  void _showTagOptionsSheet(Tag tag) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tagColor = parseTagColor(
      tag.color,
      fallback: theme.colorScheme.primary,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF262A36), const Color(0xFF1C1E26)]
                : [Colors.white, const Color(0xFFF8F9FC)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Tag header with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(LucideIcons.hash, color: tagColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tag.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${tag.noteCount} notes',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action buttons
                _buildSheetAction(
                  icon: LucideIcons.pencil,
                  label: 'Rename tag',
                  theme: theme,
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameSheet(tag);
                  },
                ),
                const SizedBox(height: 8),
                _buildSheetAction(
                  icon: LucideIcons.trash2,
                  label: 'Delete tag',
                  theme: theme,
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteSheet(tag);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetAction({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color.withValues(alpha: 0.8)),
              const SizedBox(width: 14),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: color.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameSheet(Tag tag) {
    final controller = TextEditingController(text: tag.name);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tagColor = parseTagColor(
      tag.color,
      fallback: theme.colorScheme.primary,
    );
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF262A36), const Color(0xFF1C1E26)]
                    : [Colors.white, const Color(0xFFF8F9FC)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Rename Tag',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input field
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: theme.textTheme.bodyLarge,
                      onChanged: (_) {
                        if (errorMessage != null) {
                          setState(() => errorMessage = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Tag name',
                        prefixIcon: Icon(
                          LucideIcons.hash,
                          color: errorMessage != null
                              ? theme.colorScheme.error
                              : tagColor,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.05,
                        ),
                        errorText: errorMessage,
                        errorStyle: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: errorMessage != null
                                ? theme.colorScheme.error
                                : tagColor,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.error,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.error,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final newName = controller.text.trim();
                              if (newName.isEmpty) return;

                              // If name hasn't changed, just close
                              if (newName == tag.name) {
                                if (context.mounted) Navigator.pop(context);
                                return;
                              }

                              try {
                                await ref
                                    .read(tagsControllerProvider.notifier)
                                    .updateTag(tag.copyWith(name: newName));
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                setState(() {
                                  errorMessage = e.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  );
                                });
                              }
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Rename'),
                          ),
                        ),
                      ],
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

  void _showDeleteSheet(Tag tag) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF262A36), const Color(0xFF1C1E26)]
                : [Colors.white, const Color(0xFFF8F9FC)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Warning icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.alertTriangle,
                    color: theme.colorScheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Delete Tag',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Message
                Text(
                  'Delete "${tag.name}"? This will remove it from all notes.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          await ref
                              .read(tagsControllerProvider.notifier)
                              .deleteTag(tag.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: theme.colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateTagSheet() {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF262A36), const Color(0xFF1C1E26)]
                    : [Colors.white, const Color(0xFFF8F9FC)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'New Tag',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a tag to organize your notes',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input field
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: theme.textTheme.bodyLarge,
                      onChanged: (_) {
                        if (errorMessage != null) {
                          setState(() => errorMessage = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Tag name',
                        prefixIcon: Icon(
                          LucideIcons.hash,
                          color: errorMessage != null
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.05,
                        ),
                        errorText: errorMessage,
                        errorStyle: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: errorMessage != null
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.error,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.error,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final name = controller.text.trim();
                              if (name.isEmpty) return;

                              try {
                                await ref
                                    .read(tagsControllerProvider.notifier)
                                    .createTag(name);
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                setState(() {
                                  errorMessage = e.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  );
                                });
                              }
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Create'),
                          ),
                        ),
                      ],
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

class _TagItemWidget extends StatelessWidget {
  final Tag tag;
  final bool isSelected;
  final Color tagColor;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TagItemWidget({
    required this.tag,
    required this.isSelected,
    required this.tagColor,
    required this.theme,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? tagColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.hash, size: 16, color: tagColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tag.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? tagColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Text(
                  '${tag.noteCount}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
