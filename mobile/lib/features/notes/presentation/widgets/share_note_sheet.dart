import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/note_share.dart';
import '../../domain/note_share_permission.dart';
import '../../domain/user_search_result.dart';
import '../../data/repository/users_repository.dart';
import '../../data/repository/note_shares_repository.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/network/server_config_provider.dart';

class ShareNoteSheet extends ConsumerStatefulWidget {
  final String noteId;

  const ShareNoteSheet({super.key, required this.noteId});

  @override
  ConsumerState<ShareNoteSheet> createState() => _ShareNoteSheetState();
}

class _ShareNoteSheetState extends ConsumerState<ShareNoteSheet> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<UserSearchResult> _searchResults = [];
  List<NoteShare> _shares = [];
  bool _isSearching = false;
  bool _isLoadingShares = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadShares();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final query = _searchController.text;

    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchUsers(query);
    });
  }

  Future<void> _loadShares() async {
    try {
      final repository = ref.read(noteSharesRepositoryProvider);
      final shares = await repository.getNoteShares(widget.noteId);
      if (mounted) {
        setState(() {
          _shares = shares;
          _isLoadingShares = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingShares = false);
        AppSnackbar.showError(context, message: 'Failed to load shares');
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _isSearching = true);
    try {
      final repository = ref.read(usersRepositoryProvider);
      final results = await repository.searchUsers(query);
      if (mounted) {
        final sharedUserIds = _shares.map((s) => s.sharedWithUser.id).toSet();
        setState(() {
          _searchResults = results
              .where((u) => !sharedUserIds.contains(u.id))
              .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _shareWithUser(
    UserSearchResult user,
    NoteSharePermission permission,
  ) async {
    try {
      final repository = ref.read(noteSharesRepositoryProvider);
      await repository.shareNote(widget.noteId, user.id, permission);
      if (mounted) {
        _searchController.clear();
        setState(() => _searchResults = []);
        AppSnackbar.showSuccess(context, message: 'Shared with ${user.name}');
        _loadShares();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Failed to share');
      }
    }
  }

  Future<void> _updatePermission(
    String shareId,
    NoteSharePermission permission,
  ) async {
    try {
      final repository = ref.read(noteSharesRepositoryProvider);
      await repository.updateNoteSharePermission(
        widget.noteId,
        shareId,
        permission,
      );
      await _loadShares();
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Failed to update');
      }
    }
  }

  Future<void> _revokeShare(NoteShare share) async {
    try {
      final repository = ref.read(noteSharesRepositoryProvider);
      await repository.revokeShare(widget.noteId, share.id);
      await _loadShares();
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          message: 'Removed ${share.sharedWithUser.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Failed to remove');
      }
    }
  }

  void _showPermissionPicker(UserSearchResult user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PermissionPickerSheet(
        userName: user.name,
        onSelect: (permission) {
          Navigator.pop(ctx);
          _shareWithUser(user, permission);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final serverUrl = ref.watch(serverUrlProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.userPlus,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Note',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Collaborate with others',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search by email...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.05,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Flexible(
              child: _searchResults.isNotEmpty
                  ? _buildSearchResults(theme, serverUrl)
                  : _buildSharesList(theme, serverUrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme, String? serverUrl) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Results', theme),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final user = _searchResults[index];
            return _UserTile(
              name: user.name,
              email: user.email,
              profileImage: user.profileImage,
              serverUrl: serverUrl,
              trailing: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.plus, size: 16),
                ),
                onPressed: () => _showPermissionPicker(user),
              ),
              onTap: () => _showPermissionPicker(user),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSharesList(ThemeData theme, String? serverUrl) {
    if (_isLoadingShares) {
      return const Center(heightFactor: 3, child: CircularProgressIndicator());
    }

    if (_shares.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.users,
                size: 32,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Not shared yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Search by email to invite collaborators',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Collaborators', theme),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: _shares.length,
          itemBuilder: (context, index) {
            final share = _shares[index];
            return _UserTile(
              name: share.sharedWithUser.name,
              email: share.sharedWithUser.email,
              profileImage: share.sharedWithUser.profileImage,
              serverUrl: serverUrl,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PermissionChip(
                    permission: share.permission,
                    onTap: () => _showEditPermissionSheet(share),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => _revokeShare(share),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showEditPermissionSheet(NoteShare share) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PermissionPickerSheet(
        userName: share.sharedWithUser.name,
        currentPermission: share.permission,
        onSelect: (permission) {
          Navigator.pop(ctx);
          _updatePermission(share.id, permission);
        },
      ),
    );
  }
}

// Permission picker bottom sheet
class _PermissionPickerSheet extends StatelessWidget {
  final String userName;
  final NoteSharePermission? currentPermission;
  final ValueChanged<NoteSharePermission> onSelect;

  const _PermissionPickerSheet({
    required this.userName,
    this.currentPermission,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                currentPermission == null
                    ? 'Share with $userName'
                    : 'Change permission',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _PermissionOption(
              icon: LucideIcons.eye,
              title: 'Viewer',
              subtitle: 'Can view but not edit',
              isSelected: currentPermission == NoteSharePermission.viewer,
              onTap: () => onSelect(NoteSharePermission.viewer),
            ),
            _PermissionOption(
              icon: LucideIcons.edit3,
              title: 'Editor',
              subtitle: 'Can view and edit',
              isSelected: currentPermission == NoteSharePermission.editor,
              onTap: () => onSelect(NoteSharePermission.editor),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PermissionOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PermissionOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.check, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

// Permission chip widget
class _PermissionChip extends StatelessWidget {
  final NoteSharePermission permission;
  final VoidCallback onTap;

  const _PermissionChip({required this.permission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditor = permission == NoteSharePermission.editor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEditor ? LucideIcons.edit3 : LucideIcons.eye,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              isEditor ? 'Editor' : 'Viewer',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              LucideIcons.chevronDown,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable user tile
class _UserTile extends StatelessWidget {
  final String name;
  final String email;
  final String? profileImage;
  final String? serverUrl;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _UserTile({
    required this.name,
    required this.email,
    this.profileImage,
    this.serverUrl,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                _buildAvatar(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    if (profileImage != null && profileImage!.isNotEmpty) {
      // Construct full URL if profileImage is a relative path
      String imageUrl = profileImage!;
      if (!imageUrl.startsWith('http') && serverUrl != null) {
        imageUrl = '$serverUrl$imageUrl';
      }
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => _fallbackAvatar(theme),
          errorWidget: (context, url, error) => _fallbackAvatar(theme),
        ),
      );
    }
    return _fallbackAvatar(theme);
  }

  Widget _fallbackAvatar(ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
