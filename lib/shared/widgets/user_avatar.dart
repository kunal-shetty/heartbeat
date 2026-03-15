import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  final bool isOnline;
  final bool isGroup;
  final bool showOnlineDot;

  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 48,
    this.isOnline = false,
    this.isGroup = false,
    this.showOnlineDot = true,
  });

  // Deterministic color from name
  Color _avatarColor() {
    final colors = [
      AppTheme.brandPrimaryLight,
      const Color(0xFFDBEAFE),
      const Color(0xFFFCE7F3),
      const Color(0xFFD1FAE5),
      const Color(0xFFEDE9FE),
      const Color(0xFFFED7AA),
    ];
    final index = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  Color _avatarTextColor() {
    final colors = [
      AppTheme.brandPrimaryDeep,
      const Color(0xFF1D4ED8),
      const Color(0xFF9D174D),
      const Color(0xFF065F46),
      const Color(0xFF5B21B6),
      const Color(0xFF92400E),
    ];
    final index = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl!,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    placeholder: (_, __) => _Placeholder(
                      name: name,
                      size: size,
                      bgColor: _avatarColor(),
                      textColor: _avatarTextColor(),
                      isGroup: isGroup,
                    ),
                    errorWidget: (_, __, ___) => _Placeholder(
                      name: name,
                      size: size,
                      bgColor: _avatarColor(),
                      textColor: _avatarTextColor(),
                      isGroup: isGroup,
                    ),
                  )
                : _Placeholder(
                    name: name,
                    size: size,
                    bgColor: _avatarColor(),
                    textColor: _avatarTextColor(),
                    isGroup: isGroup,
                  ),
          ),
        ),
        if (showOnlineDot && isOnline && size >= 36)
          Positioned(
            bottom: size * 0.04,
            right: size * 0.04,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: AppTheme.statusOnline,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String name;
  final double size;
  final Color bgColor;
  final Color textColor;
  final bool isGroup;

  const _Placeholder({
    required this.name,
    required this.size,
    required this.bgColor,
    required this.textColor,
    required this.isGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: bgColor,
      alignment: Alignment.center,
      child: isGroup
          ? Icon(Icons.group, color: textColor, size: size * 0.45)
          : Text(
              name.initials,
              style: TextStyle(
                color: textColor,
                fontSize: size * 0.35,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
