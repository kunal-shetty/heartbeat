import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../../../shared/widgets/user_avatar.dart';

class CallScreen extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic>? callData;

  const CallScreen({super.key, required this.chatId, this.callData});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isSpeaker = true;
  bool _isVideo = false;
  bool _isCameraOff = false;
  String? _callId;
  DateTime? _callStart;

  @override
  void initState() {
    super.initState();
    _isVideo = widget.callData?['isVideo'] as bool? ?? false;
    _logCallStart();
  }

  Future<void> _logCallStart() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticatedState) return;
    final calleeId = widget.callData?['calleeId'] as String?;
    if (calleeId == null) return;

    try {
      final res = await Supabase.instance.client
          .from(SupabaseConstants.callsTable)
          .insert({
            'chat_id': widget.chatId,
            'caller_id': auth.user.id,
            'callee_id': calleeId,
            'type': _isVideo ? 'video' : 'audio',
            'status': 'ongoing',
            'started_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      _callId = res['id'] as String?;
      _callStart = DateTime.now();
    } catch (_) {}
  }

  Future<void> _endCall() async {
    if (_callId != null) {
      final duration = _callStart != null
          ? DateTime.now().difference(_callStart!).inSeconds
          : 0;
      try {
        await Supabase.instance.client
            .from(SupabaseConstants.callsTable)
            .update({
              'status': 'answered',
              'ended_at': DateTime.now().toIso8601String(),
              'duration_s': duration,
            })
            .eq('id', _callId!);
      } catch (_) {}
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final chatName = widget.callData?['chatName'] as String? ?? 'Call';
    final avatarUrl = widget.callData?['avatarUrl'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.neutral900,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFDB2777), // deep pink
                  Color(0xFFEC4899), // pink
                  Color(0xFFF97316), // orange
                  Color(0xFF1C1917), // dark
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          // Blur circles for depth
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandOrange.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandPrimary.withOpacity(0.15),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white, size: 28),
                        onPressed: () async => await _endCall(),
                      ),
                      const Spacer(),
                      if (_isVideo)
                        IconButton(
                          icon: const Icon(Icons.flip_camera_ios_outlined,
                              color: Colors.white),
                          onPressed: () {},
                        ),
                    ],
                  ),
                ),

                // Avatar + name
                const Spacer(),
                // Avatar with pulse ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    UserAvatar(
                      name: chatName,
                      avatarUrl: avatarUrl,
                      size: 92,
                      showOnlineDot: false,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  chatName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isVideo ? 'Video calling...' : 'Calling...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const Spacer(),

                // Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 52),
                  child: Column(
                    children: [
                      // Top row of controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CallButton(
                            icon: _isMuted ? Icons.mic_off : Icons.mic,
                            label: _isMuted ? 'Unmute' : 'Mute',
                            onTap: () =>
                                setState(() => _isMuted = !_isMuted),
                            active: _isMuted,
                          ),
                          if (_isVideo)
                            _CallButton(
                              icon: _isCameraOff
                                  ? Icons.videocam_off
                                  : Icons.videocam,
                              label: _isCameraOff ? 'Cam Off' : 'Camera',
                              onTap: () =>
                                  setState(() => _isCameraOff = !_isCameraOff),
                              active: _isCameraOff,
                            ),
                          _CallButton(
                            icon: _isSpeaker
                                ? Icons.volume_up
                                : Icons.volume_off,
                            label: 'Speaker',
                            onTap: () =>
                                setState(() => _isSpeaker = !_isSpeaker),
                            active: _isSpeaker,
                          ),
                          _CallButton(
                            icon: Icons.message_outlined,
                            label: 'Message',
                            onTap: () => context.pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // End call button
                      GestureDetector(
                        onTap: _endCall,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppTheme.statusError,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x55EF4444),
                                blurRadius: 20,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                          child: const Icon(Icons.call_end,
                              color: Colors.white, size: 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.brandPink
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
