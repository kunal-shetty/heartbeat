import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../injection_container.dart' as di;
import '../../../chat/domain/repositories/chat_repository.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});
  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filtered = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filter);
  }

  Future<void> _loadContacts() async {
    final currentUserId =
        (context.read<AuthBloc>().state as AuthAuthenticatedState?)?.user.id;
    if (currentUserId == null) return;

    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.usersTable)
          .select('id, display_name, username, avatar_url')
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

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _contacts
          : _contacts.where((c) {
              return (c['display_name'] as String)
                      .toLowerCase()
                      .contains(q) ||
                  (c['username'] as String).toLowerCase().contains(q);
            }).toList();
    });
  }

  void _toggle(String userId) {
    setState(() {
      if (_selectedIds.contains(userId)) {
        _selectedIds.remove(userId);
      } else {
        _selectedIds.add(userId);
      }
    });
  }

  void _next() {
    if (_selectedIds.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GroupInfoSheet(
        selectedContacts: _contacts
            .where((c) => _selectedIds.contains(c['id']))
            .toList(),
        onCreateGroup: _createGroup,
      ),
    );
  }

  Future<void> _createGroup(String name) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticatedState) return;

    try {
      final chat = await di.sl<ChatRepository>().createGroupChat(
        createdBy: auth.user.id,
        name: name,
        participantIds: _selectedIds.toList(),
      );
      if (mounted) {
        context.pop(); // close sheet
        context.pop(); // close create group screen
        context.push('/chats/chat/${chat.id}', extra: {
          'chatName': name,
          'isGroup': true,
          'isOnline': false,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
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
    final selected =
        _contacts.where((c) => _selectedIds.contains(c['id'])).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Participants'),
            Text('${_selectedIds.length} selected',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.85))),
          ],
        ),
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: _next,
              child: const Text('Next',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppTheme.neutral400),
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
              ),
            ),
          ),

          // Selected chips
          if (selected.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: selected.length,
                itemBuilder: (_, i) {
                  final c = selected[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InputChip(
                      label: Text(c['display_name'] as String),
                      avatar: UserAvatar(
                          name: c['display_name'] as String, size: 20),
                      onDeleted: () => _toggle(c['id'] as String),
                      backgroundColor: AppTheme.brandPrimaryLight,
                      labelStyle: const TextStyle(
                          color: AppTheme.brandPrimaryDeep,
                          fontWeight: FontWeight.w500),
                      deleteIconColor: AppTheme.brandPrimaryDeep,
                      side: BorderSide.none,
                    ),
                  );
                },
              ),
            ),
          ],

          const Divider(height: 1),

          // Contact list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.brandPrimary))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final c = _filtered[index];
                      final id = c['id'] as String;
                      final selected = _selectedIds.contains(id);

                      return ListTile(
                        onTap: () => _toggle(id),
                        leading: UserAvatar(
                          name: c['display_name'] as String,
                          avatarUrl: c['avatar_url'] as String?,
                          size: 44,
                        ),
                        title: Text(c['display_name'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: AppTheme.neutral900)),
                        subtitle: Text('@${c['username']}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.neutral400)),
                        trailing: Checkbox(
                          value: selected,
                          onChanged: (_) => _toggle(id),
                          shape: const CircleBorder(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroupInfoSheet extends StatefulWidget {
  final List<Map<String, dynamic>> selectedContacts;
  final Future<void> Function(String name) onCreateGroup;

  const _GroupInfoSheet({
    required this.selectedContacts,
    required this.onCreateGroup,
  });

  @override
  State<_GroupInfoSheet> createState() => _GroupInfoSheetState();
}

class _GroupInfoSheetState extends State<_GroupInfoSheet> {
  final _nameController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.neutral400.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Group Info',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                '${widget.selectedContacts.length} participant${widget.selectedContacts.length > 1 ? 's' : ''} selected',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.neutral400)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Group name',
                prefixIcon:
                    Icon(Icons.group_outlined, color: AppTheme.neutral400),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _creating || _nameController.text.trim().isEmpty
                  ? null
                  : () async {
                      setState(() => _creating = true);
                      await widget.onCreateGroup(_nameController.text.trim());
                    },
              child: _creating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}
