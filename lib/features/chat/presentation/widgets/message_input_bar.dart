import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/chat_entity.dart';
import '../../../../core/theme/app_theme.dart';

class MessageInputBar extends StatefulWidget {
  final ValueChanged<String> onSendText;
  final void Function(String path, MessageType type) onSendMedia;
  final ValueChanged<bool> onTyping;

  const MessageInputBar({
    super.key,
    required this.onSendText,
    required this.onSendMedia,
    required this.onTyping,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _isRecording = false;
  Timer? _typingTimer;
  final _imagePicker = ImagePicker();
final _audioRecorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
      _onTyping();
    });
  }

  void _onTyping() {
    widget.onTyping(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      widget.onTyping(false);
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
    widget.onTyping(false);
    _typingTimer?.cancel();
  }

  Future<void> _pickImage() async {
    Navigator.pop(context);
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (file != null) widget.onSendMedia(file.path, MessageType.image);
  }

  Future<void> _pickCamera() async {
    Navigator.pop(context);
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (file != null) widget.onSendMedia(file.path, MessageType.image);
  }

  Future<void> _pickDocument() async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'xlsx', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      widget.onSendMedia(result.files.single.path!, MessageType.document);
    }
  }

  Future<void> _startRecording() async {
  final hasPermission = await _audioRecorder.hasPermission();
  if (!hasPermission) return;

  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

  // record v5: start() takes RecordConfig as named param, path as named param
  await _audioRecorder.start(
    const RecordConfig(encoder: AudioEncoder.aacLc),
    path: path,
  );
  setState(() => _isRecording = true);
}

  Future<void> _stopRecording() async {
    // record v4: stop() returns the file path
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null) widget.onSendMedia(path, MessageType.audio);
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.neutral400.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AttachOption(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    color: AppTheme.statusInfo,
                    onTap: _pickImage),
                _AttachOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    color: AppTheme.brandAccent,
                    onTap: _pickCamera),
                _AttachOption(
                    icon: Icons.description_outlined,
                    label: 'Document',
                    color: AppTheme.brandPrimaryDeep,
                    onTap: _pickDocument),
                _AttachOption(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    color: AppTheme.statusOnline,
                    onTap: () => Navigator.pop(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach button
                _IconBtn(icon: Icons.attach_file, onTap: _showAttachSheet),

                // Text field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPrimarySurface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppTheme.neutral900),
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 4, bottom: 4),
                          child: _IconBtn(
                            icon: Icons.emoji_emotions_outlined,
                            size: 20,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Send / Mic
                _isRecording
                    ? GestureDetector(
                        onTap: _stopRecording,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppTheme.statusError,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.stop,
                              color: Colors.white, size: 22),
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: _hasText
                            ? GestureDetector(
                                key: const ValueKey('send'),
                                onTap: _send,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.brandPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.send_rounded,
                                      color: Colors.white, size: 20),
                                ),
                              )
                            : GestureDetector(
                                key: const ValueKey('mic'),
                                onLongPressStart: (_) => _startRecording(),
                                onLongPressEnd: (_) => _stopRecording(),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.brandPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.mic,
                                      color: Colors.white, size: 22),
                                ),
                              ),
                      ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _IconBtn({required this.icon, required this.onTap, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: AppTheme.neutral400, size: size),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
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
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppTheme.neutral600)),
        ],
      ),
    );
  }
}
