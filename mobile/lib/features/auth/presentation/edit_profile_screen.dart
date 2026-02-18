import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:anchor/core/widgets/app_snackbar.dart';
import 'package:anchor/core/widgets/settings_card.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/features/auth/presentation/auth_controller.dart';
import 'package:anchor/features/auth/data/repository/auth_repository.dart';
import 'package:anchor/features/auth/domain/user.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _profileImageUrl;
  bool _isSaving = false;
  bool _shouldRemoveImage = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current user data
    final userAsync = ref.read(authControllerProvider);
    userAsync.whenData((user) {
      if (user != null) {
        _nameController.text = user.name;
        _profileImageUrl = user.profileImage;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _shouldRemoveImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userAsync = ref.read(authControllerProvider);
      final currentUser = userAsync.value;

      if (currentUser == null) {
        throw Exception('User not found');
      }

      final name = _nameController.text.trim();
      await authRepo.updateProfile(name: name.isNotEmpty ? name : null);

      // Upload image if selected (takes precedence over removal)
      User? updatedUser;
      if (_selectedImage != null) {
        updatedUser = await authRepo.uploadProfileImage(_selectedImage!);
      } else if (_shouldRemoveImage && currentUser.profileImage != null) {
        // Remove image if flag is set and no new file is selected
        updatedUser = await authRepo.removeProfileImage();
      }

      // Refresh user data
      ref.invalidate(authControllerProvider);

      if (mounted) {
        setState(() {
          if (updatedUser != null) {
            _profileImageUrl = updatedUser.profileImage;
          }
          _selectedImage = null;
          _shouldRemoveImage = false;
        });

        AppSnackbar.showSuccess(
          context,
          message: 'Profile updated successfully',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _removeImage() async {
    // Set flag to remove image on save
    setState(() {
      _shouldRemoveImage = true;
      _selectedImage = null;
      _profileImageUrl = null;
    });
  }

  Widget _buildImageActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : isPrimary
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: isDestructive || isPrimary ? 0.1 : 0.05,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userAsync = ref.watch(authControllerProvider);
    final serverUrl = ref.watch(serverUrlProvider);

    // Update profile image when user data changes
    userAsync.whenData((user) {
      if (user != null && _profileImageUrl != user.profileImage) {
        _profileImageUrl = user.profileImage;
      }
    });

    String? getProfileImageUrl() {
      if (_selectedImage != null) return null; // Will use FileImage
      if (_shouldRemoveImage) return null; // Image marked for removal
      if (_profileImageUrl == null) return null;
      if (_profileImageUrl!.startsWith('http')) return _profileImageUrl;
      final url = serverUrl;
      if (url == null) return null;
      return '$url$_profileImageUrl';
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1C1E26), const Color(0xFF262A36)]
                : [const Color(0xFFF8F9FC), const Color(0xFFEEF1F8)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              floating: true,
              pinned: true,
              expandedHeight: 120,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: Platform.isIOS,
                titlePadding: EdgeInsets.only(
                  left: 56,
                  right: Platform.isIOS ? 56 : 0,
                  bottom: 12,
                ),
                title: Text(
                  'Edit Profile',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            // Form Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: SettingsCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Image Section
                        Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: theme.colorScheme.surface,
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : (getProfileImageUrl() != null
                                              ? CachedNetworkImageProvider(
                                                  getProfileImageUrl()!,
                                                )
                                              : null)
                                          as ImageProvider?,
                                child:
                                    _selectedImage == null &&
                                        getProfileImageUrl() == null
                                    ? Icon(
                                        LucideIcons.user,
                                        size: 56,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.4),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildImageActionButton(
                                  context,
                                  icon: LucideIcons.upload,
                                  label: 'Change Photo',
                                  onPressed: _pickImage,
                                  isPrimary: true,
                                ),
                                if ((getProfileImageUrl() != null ||
                                        _selectedImage != null) &&
                                    !_shouldRemoveImage)
                                  _buildImageActionButton(
                                    context,
                                    icon: LucideIcons.trash2,
                                    label: 'Remove',
                                    onPressed: _removeImage,
                                    isDestructive: true,
                                  ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Divider
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.1,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Name Input Section
                        Text(
                          'Update your profile information',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _saveProfile(),
                          decoration: InputDecoration(
                            labelText: 'Name',
                            hintText: 'Enter your name',
                            prefixIcon: const Icon(LucideIcons.user),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.white.withValues(alpha: 0.6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Profile'),
                        ),
                      ],
                    ),
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
