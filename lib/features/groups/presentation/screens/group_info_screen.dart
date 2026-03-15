import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/user_avatar.dart';

class GroupInfoScreen extends StatelessWidget {
  final String groupId;
  const GroupInfoScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Group Info'),
              background: Container(
                color: AppTheme.brandPrimary,
                child: const Center(
                  child: UserAvatar(
                    name: 'Group',
                    size: 80,
                    isGroup: true,
                    showOnlineDot: false,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Group Name',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppTheme.brandPrimaryDark,
                                fontWeight: FontWeight.w600,
                              )),
                      const SizedBox(height: 4),
                      Text('Team Flutter 🚀',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.neutral900)),
                      const SizedBox(height: 12),
                      Text('Created by You • 3 participants',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.neutral400)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text('3 Participants',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                    color: AppTheme.brandPrimary,
                                    fontWeight: FontWeight.w600)),
                      ),
                      ListTile(
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                              color: AppTheme.brandPrimaryLight,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.person_add,
                              color: AppTheme.brandPrimaryDeep, size: 22),
                        ),
                        title: Text('Add Participants',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    color: AppTheme.brandPrimary,
                                    fontWeight: FontWeight.w600)),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 72),
                      // Member tiles would be populated from data
                      ListTile(
                        leading: const UserAvatar(name: 'You', size: 44),
                        title: const Text('You'),
                        subtitle: const Text('Admin'),
                        trailing: const Text('Admin',
                            style: TextStyle(
                                color: AppTheme.brandPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.exit_to_app,
                            color: AppTheme.statusError),
                        title: const Text('Exit Group',
                            style: TextStyle(color: AppTheme.statusError)),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.delete_sweep_outlined,
                            color: AppTheme.statusError),
                        title: const Text('Delete Group',
                            style: TextStyle(color: AppTheme.statusError)),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
