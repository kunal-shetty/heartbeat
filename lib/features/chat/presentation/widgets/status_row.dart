import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/user_avatar.dart';

class StatusRow extends StatelessWidget {
  const StatusRow({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo data — replace with real contacts
    final contacts = [
      {'name': 'Priya', 'online': true},
      {'name': 'Aarav', 'online': false},
      {'name': 'Bhavna', 'online': true},
      {'name': 'Rahul', 'online': false},
      {'name': 'Neha', 'online': true},
      {'name': 'Kiran', 'online': false},
    ];

    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // "My Status" / Add story
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.brandPrimaryLight,
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppTheme.brandPrimaryLight,
                          child: const Icon(Icons.person,
                              color: AppTheme.brandPrimaryDeep, size: 24),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppTheme.brandPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'My status',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.neutral600,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Contacts
          ...contacts.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () {},
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.brandPrimary,
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      child: UserAvatar(
                        name: c['name'] as String,
                        size: 48,
                        isOnline: c['online'] as bool,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c['name'] as String,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.neutral600,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
