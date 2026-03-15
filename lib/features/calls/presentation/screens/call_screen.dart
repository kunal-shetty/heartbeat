import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _isVideo = widget.callData?['isVideo'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final chatName = widget.callData?['chatName'] as String? ?? 'Call';

    return Scaffold(
      backgroundColor: AppTheme.neutral900,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.brandPrimaryDark.withOpacity(0.9),
                  AppTheme.neutral900,
                ],
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
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),

                // Avatar + name
                const Spacer(),
                UserAvatar(
                  name: chatName,
                  size: 96,
                  showOnlineDot: false,
                ),
                const SizedBox(height: 20),
                Text(
                  chatName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isVideo ? 'Video call...' : 'Calling...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const Spacer(),

                // Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CallButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        onTap: () => setState(() => _isMuted = !_isMuted),
                      ),
                      if (_isVideo)
                        _CallButton(
                          icon: Icons.flip_camera_ios_outlined,
                          label: 'Flip',
                          onTap: () {},
                        ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: AppTheme.statusError,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end,
                              color: Colors.white, size: 30),
                        ),
                      ),
                      _CallButton(
                        icon: _isSpeaker
                            ? Icons.volume_up
                            : Icons.volume_down,
                        label: 'Speaker',
                        onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                        active: _isSpeaker,
                      ),
                      if (_isVideo)
                        _CallButton(
                          icon: Icons.videocam_off_outlined,
                          label: 'Video',
                          onTap: () => setState(() => _isVideo = !_isVideo),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.brandPrimary
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
