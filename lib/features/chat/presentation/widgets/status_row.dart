import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../../../shared/widgets/user_avatar.dart';

/// Horizontal story-ring row at the top of the Chats tab.
/// Shows online users pulled directly from public.users (is_online = true).
class StatusRow extends StatefulWidget {
  const StatusRow({super.key});

  @override
  State<StatusRow> createState() => _StatusRowState();
}

class _StatusRowState extends State<StatusRow> {
  List<Map<String, dynamic>> _onlineUsers = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticatedState) return;
    _currentUserId = auth.user.id;

    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.usersTable)
          .select('id, display_name, avatar_url, is_online')
          .eq('is_online', true)
          .neq('id', _currentUserId!)
          .limit(20);

      if (mounted) {
        setState(() {
          _onlineUsers = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    final me = auth is AuthAuthenticatedState ? auth.user : null;

    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          // My status bubble
          _StatusBubble(
            name: 'My Status',
            avatarUrl: me?.avatarUrl,
            isMe: true,
            isOnline: true,
            gradient: AppTheme.heroGradient,
            onTap: () {},
          ),

          // Online contacts
          ..._onlineUsers.map((u) => _StatusBubble(
                name: (u['display_name'] as String? ?? 'User')
                    .split(' ')
                    .first,
                avatarUrl: u['avatar_url'] as String?,
                isOnline: true,
                gradient: AppTheme.heroGradient,
                onTap: () {},
              )),
        ],
      ),
    );
  }
}

class _StatusBubble extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final bool isMe;
  final Gradient gradient;
  final VoidCallback onTap;

  const _StatusBubble({
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    required this.gradient,
    required this.onTap,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradient,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: UserAvatar(
                      name: name,
                      avatarUrl: avatarUrl,
                      size: 44,
                      showOnlineDot: false,
                    ),
                  ),
                ),
                if (isMe)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              name.length > 8 ? '${name.substring(0, 7)}..' : name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.neutral700,
                    fontSize: 10.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
