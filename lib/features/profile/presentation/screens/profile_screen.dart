import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/profile_bloc.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../injection_container.dart' as di;

class ProfileScreen extends StatefulWidget {
  final bool isTab;
  const ProfileScreen({super.key, this.isTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    _profileBloc = di.sl<ProfileBloc>();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticatedState) {
      _profileBloc.add(ProfileLoadEvent(auth.user.id));
    }
  }

  @override
  void dispose() {
    _profileBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _profileBloc,
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final user = state is ProfileLoadedState
              ? state.user
              : state is ProfileUpdatingState
                  ? state.user
                  : null;

          final auth = context.read<AuthBloc>().state;
          final authUser =
              auth is AuthAuthenticatedState ? auth.user : null;

          final displayUser = user ?? authUser;

          return Scaffold(
            backgroundColor: AppTheme.neutral100,
            appBar: widget.isTab
                ? AppBar(
                    title: const Text('Settings'),
                    actions: [
                      if (displayUser != null)
                        TextButton(
                          onPressed: () => context.push(AppRoutes.editProfile),
                          child: const Text('Edit',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  )
                : AppBar(
                    title: const Text('Profile'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => context.push(AppRoutes.editProfile),
                        child: const Text('Edit',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
            body: displayUser == null
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.brandPrimary))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          color: AppTheme.brandPrimary,
                          padding: const EdgeInsets.fromLTRB(0, 20, 0, 32),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  UserAvatar(
                                    name: displayUser.displayName,
                                    avatarUrl: displayUser.avatarUrl,
                                    size: 80,
                                    showOnlineDot: false,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppTheme.brandAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                displayUser.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayUser.phone ??
                                    displayUser.email ??
                                    '@${displayUser.username}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Colors.white.withOpacity(0.85)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // About
                        _Section(children: [
                          _AboutTile(
                            icon: Icons.info_outline,
                            label: 'About',
                            value: displayUser.statusMsg,
                          ),
                        ]),

                        const SizedBox(height: 8),

                        // Main settings
                        _Section(children: [
                          _SettingsTile(
                            icon: Icons.photo_library_outlined,
                            iconBg: AppTheme.brandPrimaryLight,
                            iconColor: AppTheme.brandPrimaryDeep,
                            label: 'Media, Links & Docs',
                            onTap: () {},
                          ),
                          const Divider(height: 1, indent: 64),
                          _SettingsTile(
                            icon: Icons.notifications_outlined,
                            iconBg: const Color(0xFFFEE2E2),
                            iconColor: AppTheme.statusError,
                            label: 'Notifications',
                            onTap: () {},
                          ),
                          const Divider(height: 1, indent: 64),
                          _SettingsTile(
                            icon: Icons.lock_outline,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: AppTheme.statusOnline,
                            label: 'Privacy',
                            onTap: () {},
                          ),
                          const Divider(height: 1, indent: 64),
                          _SettingsTile(
                            icon: Icons.color_lens_outlined,
                            iconBg: const Color(0xFFEDE9FE),
                            iconColor: const Color(0xFF7C3AED),
                            label: 'Theme',
                            trailing: Text('System',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.neutral400)),
                            onTap: () => _showThemeSheet(context),
                          ),
                          const Divider(height: 1, indent: 64),
                          _SettingsTile(
                            icon: Icons.storage_outlined,
                            iconBg: AppTheme.brandAccentLight,
                            iconColor: AppTheme.brandAccent,
                            label: 'Storage & Data',
                            onTap: () {},
                          ),
                        ]),

                        const SizedBox(height: 8),

                        // Help
                        _Section(children: [
                          _SettingsTile(
                            icon: Icons.help_outline,
                            iconBg: AppTheme.neutral100,
                            iconColor: AppTheme.neutral600,
                            label: 'Help',
                            onTap: () {},
                          ),
                          const Divider(height: 1, indent: 64),
                          _SettingsTile(
                            icon: Icons.info_outline,
                            iconBg: AppTheme.neutral100,
                            iconColor: AppTheme.neutral600,
                            label: 'App Info',
                            trailing: Text('v1.0.0',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.neutral400)),
                            onTap: () {},
                          ),
                        ]),

                        const SizedBox(height: 8),

                        // Sign out
                        _Section(children: [
                          _SettingsTile(
                            icon: Icons.logout_rounded,
                            iconBg: const Color(0xFFFEE2E2),
                            iconColor: AppTheme.statusError,
                            label: 'Sign Out',
                            labelColor: AppTheme.statusError,
                            showChevron: false,
                            onTap: () => _confirmSignOut(context),
                          ),
                        ]),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  void _showThemeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppTheme.neutral400.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.light_mode_outlined),
            title: const Text('Light'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.phone_android_outlined),
            title: const Text('System default'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthSignOutEvent());
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.statusError),
            child: const Text('Sign Out'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;
  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AboutTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppTheme.brandPrimary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.brandPrimaryDark,
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 3),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppTheme.neutral800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.labelColor,
    this.trailing,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: labelColor ?? AppTheme.neutral900,
              fontWeight: FontWeight.w500,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing!,
          if (showChevron)
            const Icon(Icons.chevron_right,
                color: AppTheme.neutral400, size: 20),
        ],
      ),
    );
  }
}
