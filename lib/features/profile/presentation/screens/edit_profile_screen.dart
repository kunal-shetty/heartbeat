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
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileBloc>().state;
    final user = profileState is ProfileLoadedState ? profileState.user : null;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _statusController = TextEditingController(text: user?.statusMsg ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) setState(() => _newAvatarPath = file.path);
  }

  void _save() {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticatedState) return;

    context.read<ProfileBloc>().add(ProfileUpdateEvent(
          userId: auth.user.id,
          displayName: _nameController.text.trim(),
          statusMsg: _statusController.text.trim(),
          avatarPath: _newAvatarPath,
        ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileBloc>().state;
    final user = profileState is ProfileLoadedState ? profileState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      backgroundColor: AppTheme.neutral100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  _newAvatarPath != null
                      ? CircleAvatar(
                          radius: 52,
                          backgroundImage:
                              AssetImage(_newAvatarPath!),
                        )
                      : UserAvatar(
                          name: user?.displayName ?? 'U',
                          avatarUrl: user?.avatarUrl,
                          size: 104,
                          showOnlineDot: false,
                        ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.brandPrimary,
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

            const SizedBox(height: 32),

            // Form
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Display Name',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.brandPrimaryDark,
                            fontWeight: FontWeight.w600,
                          )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppTheme.neutral900),
                    decoration: const InputDecoration(
                      hintText: 'Your name',
                      prefixIcon:
                          Icon(Icons.person_outline, color: AppTheme.neutral400),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('About',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.brandPrimaryDark,
                            fontWeight: FontWeight.w600,
                          )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _statusController,
                    maxLength: 100,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppTheme.neutral900),
                    decoration: const InputDecoration(
                      hintText: 'Something about you...',
                      prefixIcon:
                          Icon(Icons.info_outline, color: AppTheme.neutral400),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
