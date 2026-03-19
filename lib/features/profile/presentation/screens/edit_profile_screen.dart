import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../blocs/profile_bloc.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _statusController;
  String? _newAvatarPath;
  bool _isSaving = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileBloc>().state;
    final user = profileState is ProfileLoadedState
        ? profileState.user
        : profileState is ProfileUpdatingState
            ? profileState.user
            : null;
    final auth = context.read<AuthBloc>().state;
    final authUser = auth is AuthAuthenticatedState ? auth.user : null;
    final displayUser = user ?? authUser;

    _nameController =
        TextEditingController(text: displayUser?.displayName ?? '');
    _statusController =
        TextEditingController(text: displayUser?.statusMsg ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (file != null) setState(() => _newAvatarPath = file.path);
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Could not open gallery. Please try again.');
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.showSnackBar('Display name cannot be empty.');
      return;
    }
    if (name.length < 2) {
      context.showSnackBar('Name must be at least 2 characters.');
      return;
    }

    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticatedState) return;

    setState(() => _isSaving = true);
    try {
      context.read<ProfileBloc>().add(ProfileUpdateEvent(
            userId: auth.user.id,
            displayName: name,
            statusMsg: _statusController.text.trim(),
            avatarPath: _newAvatarPath,
          ));
      // Wait briefly for the bloc to process, then pop
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to save profile. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileErrorState) {
          // Show a friendly message — not the raw Supabase error
          String friendly = 'Could not save profile.';
          if (state.message.toLowerCase().contains('storage') ||
              state.message.toLowerCase().contains('bucket')) {
            friendly = 'Photo upload failed — please check your connection.';
          } else if (state.message.toLowerCase().contains('permission') ||
              state.message.toLowerCase().contains('policy') ||
              state.message.toLowerCase().contains('rls') ||
              state.message.toLowerCase().contains('row-level')) {
            friendly = 'Permission error. Please sign out and sign back in.';
          } else if (state.message.toLowerCase().contains('network') ||
              state.message.toLowerCase().contains('socket')) {
            friendly = 'No internet connection. Check your network and retry.';
          }
          context.showSnackBar(friendly);
          setState(() => _isSaving = false);
        }
        if (state is ProfileLoadedState) {
          setState(() => _isSaving = false);
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Edit Profile',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              actions: [
                _isSaving
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: _save,
                        child: const Text('Save',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
              ],
            ),
          ),
        ),
        backgroundColor: AppTheme.neutral100,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar picker
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    _newAvatarPath != null
                        ? CircleAvatar(
                            radius: 52,
                            // ✅ FileImage, not AssetImage, for local files
                            backgroundImage: FileImage(File(_newAvatarPath!)),
                          )
                        : Builder(builder: (context) {
                            final profileState =
                                context.watch<ProfileBloc>().state;
                            final user = profileState is ProfileLoadedState
                                ? profileState.user
                                : profileState is ProfileUpdatingState
                                    ? profileState.user
                                    : null;
                            final auth = context.read<AuthBloc>().state;
                            final authUser = auth is AuthAuthenticatedState
                                ? auth.user
                                : null;
                            final displayUser = user ?? authUser;
                            return UserAvatar(
                              name: displayUser?.displayName ?? 'U',
                              avatarUrl: displayUser?.avatarUrl,
                              size: 104,
                              showOnlineDot: false,
                            );
                          }),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Tap to change photo',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.neutral400)),

              const SizedBox(height: 28),

              // Form card
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8)
                    ]),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Display Name', Icons.person_outline),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                          color: AppTheme.neutral900, fontSize: 14),
                      cursorColor: AppTheme.brandPink,
                      maxLength: 50,
                      decoration: _inputDeco('Your name', Icons.person_outline),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('About', Icons.info_outline),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _statusController,
                      style: const TextStyle(
                          color: AppTheme.neutral900, fontSize: 14),
                      cursorColor: AppTheme.brandPink,
                      maxLength: 100,
                      maxLines: 2,
                      decoration: _inputDeco(
                          'Something about you...', Icons.info_outline),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Note about storage migration
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.brandPinkLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.brandPink, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'To enable photo uploads, make sure you have run the full_schema.sql migration in Supabase.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Color(0xFF9D174D)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.neutral400),
        prefixIcon: Icon(icon, color: AppTheme.neutral400, size: 20),
        filled: true,
        fillColor: AppTheme.neutral100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.brandPink, width: 1.5),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FieldLabel(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.brandPink),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.neutral700,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
