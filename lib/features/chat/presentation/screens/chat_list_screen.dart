import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../blocs/chat_list_bloc.dart';
import '../../../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../widgets/chat_list_tile.dart';
import '../widgets/status_row.dart';
import '../../../../features/profile/presentation/screens/profile_screen.dart';
import '../../../../shared/widgets/user_avatar.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChats();
  }

  void _loadChats() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticatedState) {
      _currentUserId = authState.user.id;
      context.read<ChatListBloc>().add(ChatListLoadEvent(authState.user.id));
      _setOnline(true);
    }
  }

  void _setOnline(bool online) {
    if (_currentUserId == null) return;
    Supabase.instance.client.from(SupabaseConstants.usersTable).update({
      'is_online': online,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', _currentUserId!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _setOnline(true);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) _setOnline(false);
  }

  @override
  void dispose() {
    _setOnline(false);
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _ChatsTab(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (q) => setState(() => _searchQuery = q),
          ),
          _StatusTab(currentUserId: _currentUserId),
          _CallsTab(currentUserId: _currentUserId),
          const ProfileScreen(isTab: true),
        ],
      ),
      bottomNavigationBar: _GradientNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ── Gradient bottom nav bar ────────────────────────────────────────────────

class _GradientNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _GradientNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chats'),
      (Icons.circle_outlined, Icons.circle, 'Status'),
      (Icons.call_outlined, Icons.call, 'Calls'),
      (Icons.settings_outlined, Icons.settings, 'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(items.length, (i) {
              final (outlineIcon, filledIcon, label) = items[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      selected
                          ? ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) =>
                                  AppTheme.heroGradient.createShader(bounds),
                              child:
                                  Icon(filledIcon, size: 24),
                            )
                          : Icon(outlineIcon,
                              size: 24, color: AppTheme.neutral400),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? AppTheme.brandPink
                              : AppTheme.neutral400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Chats Tab ──────────────────────────────────────────────────────────────

class _ChatsTab extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _ChatsTab({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Heartbeat',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22)),
            actions: [
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                onPressed: () => context.push(AppRoutes.newChat),
                tooltip: 'New Chat',
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => searchController.clear(),
                tooltip: 'Search',
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _showMenu(context),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              // Always use dark text so it's visible on the white/light gray background
              style: const TextStyle(
                color: AppTheme.neutral900,
                fontSize: 14,
              ),
              cursorColor: AppTheme.brandPink,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                hintStyle: const TextStyle(color: AppTheme.neutral400),
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppTheme.neutral400),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: AppTheme.neutral400),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.neutral100,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
              ),
            ),
          ),

          // Status row (real data)
          const StatusRow(),
          const Divider(height: 1),

          // Chat list
          Expanded(
            child: BlocBuilder<ChatListBloc, ChatListState>(
              builder: (context, state) {
                if (state is ChatListLoadingState) {
                  return const _ChatListSkeleton();
                }
                if (state is ChatListErrorState) {
                  return _ErrorState(
                    message: state.message,
                    onRetry: () {
                      final auth = context.read<AuthBloc>().state;
                      if (auth is AuthAuthenticatedState) {
                        context
                            .read<ChatListBloc>()
                            .add(ChatListLoadEvent(auth.user.id));
                      }
                    },
                  );
                }
                if (state is ChatListLoadedState) {
                  var chats = state.chats;
                  if (searchQuery.isNotEmpty) {
                    chats = chats
                        .where((c) => c.displayName
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()))
                        .toList();
                  }
                  if (chats.isEmpty) {
                    return _EmptyState(hasSearch: searchQuery.isNotEmpty);
                  }
                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, i) {
                      final chat = chats[i];
                      return ChatListTile(
                        chat: chat,
                        onTap: () => context.push(
                          '/chats/chat/${chat.id}',
                          extra: {
                            'chatName': chat.displayName,
                            'chatAvatar':
                                chat.avatarUrl ?? chat.otherUserAvatar,
                            'isOnline': chat.otherUserOnline ?? false,
                            'isGroup': chat.type.name == 'group',
                            'otherUserId': chat.otherUserId,
                          },
                        ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.newChat),
        backgroundColor: AppTheme.brandPink,
        child: const Icon(Icons.edit_note_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppTheme.neutral400.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.group_add_outlined,
                color: AppTheme.brandPink),
            title: const Text('New Group'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.createGroup);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_search_outlined,
                color: AppTheme.brandOrange),
            title: const Text('Find People'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.newChat);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined,
                color: AppTheme.neutral600),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Status Tab (REAL DATA) ─────────────────────────────────────────────────

class _StatusTab extends StatefulWidget {
  final String? currentUserId;
  const _StatusTab({this.currentUserId});
  @override
  State<_StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<_StatusTab> {
  List<Map<String, dynamic>> _myStatuses = [];
  List<Map<String, dynamic>> _contactStatuses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.currentUserId == null) return;
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final cutoff =
          DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();

      // My statuses
      final mine = await client
          .from(SupabaseConstants.statusUpdatesTable)
          .select('*, user:users(id, display_name, avatar_url)')
          .eq('user_id', widget.currentUserId!)
          .gte('created_at', cutoff)
          .order('created_at', ascending: false);

      // Others' statuses (users who have active statuses)
      final others = await client
          .from(SupabaseConstants.statusUpdatesTable)
          .select('*, user:users(id, display_name, avatar_url)')
          .neq('user_id', widget.currentUserId!)
          .gte('created_at', cutoff)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myStatuses = List<Map<String, dynamic>>.from(mine);
          _contactStatuses = List<Map<String, dynamic>>.from(others);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Status',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22)),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandPink))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.brandPink,
              child: ListView(
                children: [
                  // My status
                  ListTile(
                    onTap: _myStatuses.isEmpty
                        ? _addStatus
                        : () => _viewStatus(_myStatuses.first),
                    leading: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _myStatuses.isNotEmpty
                                ? AppTheme.heroGradient
                                : null,
                            color: _myStatuses.isEmpty
                                ? AppTheme.neutral100
                                : null,
                          ),
                          child: UserAvatar(
                            name: context.read<AuthBloc>().state
                                    is AuthAuthenticatedState
                                ? (context.read<AuthBloc>().state
                                        as AuthAuthenticatedState)
                                    .user
                                    .displayName
                                : 'Me',
                            size: 50,
                            showOnlineDot: false,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _addStatus,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                gradient: AppTheme.heroGradient,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: const Text('My Status',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _myStatuses.isEmpty
                          ? 'Tap to add status update'
                          : '${_myStatuses.length} update${_myStatuses.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: AppTheme.neutral400, fontSize: 13),
                    ),
                  ),
                  const Divider(height: 1, indent: 72),

                  if (_contactStatuses.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text('Recent updates',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                  color: AppTheme.neutral600,
                                  fontWeight: FontWeight.w700)),
                    ),
                    ..._contactStatuses.map((s) {
                      final user =
                          s['user'] as Map<String, dynamic>? ?? {};
                      return ListTile(
                        onTap: () => _viewStatus(s),
                        leading: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.heroGradient,
                          ),
                          child: UserAvatar(
                            name: user['display_name'] as String? ?? '?',
                            avatarUrl: user['avatar_url'] as String?,
                            size: 50,
                            showOnlineDot: false,
                          ),
                        ),
                        title: Text(user['display_name'] as String? ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          _timeAgo(DateTime.parse(s['created_at'] as String)),
                          style: const TextStyle(
                              color: AppTheme.neutral400, fontSize: 13),
                        ),
                      );
                    }),
                  ] else if (!_loading) ...[
                    const SizedBox(height: 60),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle_outlined,
                              size: 56, color: AppTheme.neutral400),
                          const SizedBox(height: 12),
                          Text('No status updates',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppTheme.neutral600)),
                          const SizedBox(height: 4),
                          Text('Follow people to see their status',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.neutral400)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStatus,
        backgroundColor: AppTheme.brandPink,
        child: const Icon(Icons.photo_camera, color: Colors.white),
      ),
    );
  }

  void _addStatus() {
    context.showSnackBar(
        'Status upload coming soon — pick a photo to share!');
  }

  void _viewStatus(Map<String, dynamic> status) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            if (status['media_url'] != null)
              Center(
                child: Image.network(status['media_url'] as String,
                    fit: BoxFit.contain),
              )
            else
              const Center(
                  child: Icon(Icons.image_not_supported,
                      color: Colors.white, size: 60)),
            if (status['caption'] != null)
              Positioned(
                bottom: 40,
                left: 16,
                right: 16,
                child: Text(
                  status['caption'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            Positioned(
              top: 40,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Calls Tab (REAL DATA) ──────────────────────────────────────────────────

class _CallsTab extends StatefulWidget {
  final String? currentUserId;
  const _CallsTab({this.currentUserId});
  @override
  State<_CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<_CallsTab> {
  List<Map<String, dynamic>> _calls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.currentUserId == null) return;
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.callsTable)
          .select('''
            *,
            caller:users!calls_caller_id_fkey(id, display_name, avatar_url),
            callee:users!calls_callee_id_fkey(id, display_name, avatar_url)
          ''')
          .or('caller_id.eq.${widget.currentUserId},callee_id.eq.${widget.currentUserId}')
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _calls = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Calls',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22)),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined, color: Colors.white),
                onPressed: () => context.push(AppRoutes.newChat),
                tooltip: 'New Call',
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandPink))
          : _calls.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.call_outlined,
                          size: 56, color: AppTheme.neutral400),
                      const SizedBox(height: 12),
                      Text('No calls yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.neutral600)),
                      const SizedBox(height: 4),
                      Text('Your call history will appear here',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.neutral400)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.brandPink,
                  child: ListView.builder(
                    itemCount: _calls.length,
                    itemBuilder: (context, i) {
                      final call = _calls[i];
                      final isOutgoing = call['caller_id'] == widget.currentUserId;
                      final other = isOutgoing
                          ? call['callee'] as Map<String, dynamic>? ?? {}
                          : call['caller'] as Map<String, dynamic>? ?? {};
                      final status = call['status'] as String;
                      final type = call['type'] as String;
                      final isVideo = type == 'video';
                      final isMissed = status == 'missed' && !isOutgoing;
                      final time = DateTime.parse(call['created_at'] as String);

                      return ListTile(
                        leading: UserAvatar(
                          name: other['display_name'] as String? ?? '?',
                          avatarUrl: other['avatar_url'] as String?,
                          size: 46,
                          showOnlineDot: false,
                        ),
                        title: Text(
                          other['display_name'] as String? ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isMissed
                                ? AppTheme.statusError
                                : AppTheme.neutral900,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              isOutgoing
                                  ? Icons.call_made_rounded
                                  : Icons.call_received_rounded,
                              size: 14,
                              color: isMissed
                                  ? AppTheme.statusError
                                  : AppTheme.statusOnline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${isOutgoing ? "Outgoing" : isMissed ? "Missed" : "Incoming"} · ${_timeAgo(time)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isMissed
                                    ? AppTheme.statusError
                                    : AppTheme.neutral400,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isVideo
                                ? Icons.videocam_outlined
                                : Icons.call_outlined,
                            color: AppTheme.brandPink,
                          ),
                          onPressed: () {
                            // Find or create chat then initiate call
                            context.push(
                              '/call/${call['chat_id'] ?? other['id']}',
                              extra: {
                                'isVideo': isVideo,
                                'chatName': other['display_name'],
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.newChat),
        backgroundColor: AppTheme.brandPink,
        child: const Icon(Icons.add_call, color: Colors.white),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({this.hasSearch = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => AppTheme.heroGradient.createShader(b),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 64),
          ),
          const SizedBox(height: 20),
          Text(
            hasSearch ? 'No chats found' : 'No conversations yet',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppTheme.neutral600),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different search'
                : 'Tap the pencil button to start chatting',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.neutral400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppTheme.neutral400),
          const SizedBox(height: 12),
          Text('Could not load chats',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppTheme.neutral600)),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.brandPink),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ChatListSkeleton extends StatelessWidget {
  const _ChatListSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                    color: AppTheme.neutral100, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 13,
                      width: 110,
                      decoration: BoxDecoration(
                          color: AppTheme.neutral100,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(
                      height: 11,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: AppTheme.neutral100,
                          borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
