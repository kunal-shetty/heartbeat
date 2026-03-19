import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../domain/entities/chat_entity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/repositories/chat_repository.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});
  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(() {
      _filter(_searchController.text);
    });
  }

  Future<void> _loadContacts() async {
    final currentUserId =
        (context.read<AuthBloc>().state as AuthAuthenticatedState?)?.user.id;
    if (currentUserId == null) return;

    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.usersTable)
          .select('id, display_name, username, avatar_url, is_online')
          .neq('id', currentUserId)
          .order('display_name');

      setState(() {
        _contacts = List<Map<String, dynamic>>.from(data);
        _filtered = _contacts;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _contacts;
      } else {
        _filtered = _contacts.where((c) {
          final name = (c['display_name'] as String).toLowerCase();
          final username = (c['username'] as String).toLowerCase();
          return name.contains(query.toLowerCase()) ||
              username.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _startChat(Map<String, dynamic> contact) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticatedState) return;

    try {
      final chat = await di.sl<ChatRepository>().createDirectChat(
        currentUserId: auth.user.id,
        otherUserId: contact['id'] as String,
      );

      if (mounted) {
        context.pop();
        context.push('/chats/chat/${chat.id}', extra: {
          'chatName': contact['display_name'],
          'chatAvatar': contact['avatar_url'],
          'isOnline': contact['is_online'] ?? false,
          'isGroup': false,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group contacts by first letter
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final c in _filtered) {
      final key = (c['display_name'] as String)[0].toUpperCase();
      grouped.putIfAbsent(key, () => []).add(c);
    }
    final keys = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('New Chat',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(
                color: AppTheme.neutral900,
                fontSize: 14,
              ),
              cursorColor: AppTheme.brandPink,
              decoration: InputDecoration(
                hintText: 'Search contacts',
                hintStyle: const TextStyle(color: AppTheme.neutral400),
                prefixIcon:
                    const Icon(Icons.search, size: 20, color: AppTheme.neutral400),
                filled: true,
                fillColor: AppTheme.neutral100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide:
                      const BorderSide(color: AppTheme.brandPink, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Quick actions
          _QuickAction(
            icon: Icons.group_add_outlined,
            label: 'New Group',
            onTap: () {
              context.pop();
              context.push('/create-group');
            },
          ),
          _QuickAction(
            icon: Icons.campaign_outlined,
            label: 'New Broadcast',
            onTap: () {},
          ),

          const Divider(height: 1),

          // Contact list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.brandPrimary))
                : _filtered.isEmpty
                    ? Center(
                        child: Text('No contacts found',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppTheme.neutral400)),
                      )
                    : ListView.builder(
                        itemCount: keys.length,
                        itemBuilder: (context, sectionIndex) {
                          final letter = keys[sectionIndex];
                          final contacts = grouped[letter]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                                color: AppTheme.neutral100,
                                child: Text(
                                  letter,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          color: AppTheme.brandPrimary,
                                          fontWeight: FontWeight.w600),
                                ),
                              ),
                              ...contacts.map(
                                (c) => ListTile(
                                  onTap: () => _startChat(c),
                                  leading: UserAvatar(
                                    name: c['display_name'] as String,
                                    avatarUrl: c['avatar_url'] as String?,
                                    size: 44,
                                    isOnline: c['is_online'] as bool? ?? false,
                                  ),
                                  title: Text(
                                    c['display_name'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(color: AppTheme.neutral900),
                                  ),
                                  subtitle: Text(
                                    '@${c['username']}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppTheme.neutral400),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.brandPrimaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.brandPrimaryDeep, size: 22),
      ),
      title: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: AppTheme.neutral900, fontWeight: FontWeight.w600),
      ),
    );
  }
}
