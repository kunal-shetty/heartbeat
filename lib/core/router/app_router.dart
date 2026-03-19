import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/signin_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/new_chat_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/group_info_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/calls/presentation/screens/call_screen.dart';
import '../errors/failure.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signIn = '/signin';
  static const otp = '/otp';
  static const register = '/register';
  static const chatList = '/chats';
  static const chat = '/chats/:chatId';
  static const newChat = '/new-chat';
  static const createGroup = '/create-group';
  static const groupInfo = '/group-info/:groupId';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const call = '/call/:chatId';
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final authBloc = context.read<AuthBloc>();
      final isAuthenticated = authBloc.state is AuthAuthenticatedState;
      final isOnAuthPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signIn ||
          state.matchedLocation == AppRoutes.otp ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.splash;

      if (!isAuthenticated && !isOnAuthPage) return AppRoutes.login;
      if (isAuthenticated && isOnAuthPage && state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.chatList;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, state) => OtpScreen(
          phone: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatList,
        builder: (_, __) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: 'chat/:chatId',
            builder: (_, state) => ChatScreen(
              chatId: state.pathParameters['chatId']!,
              chatData: state.extra as Map<String, dynamic>?,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.newChat,
        builder: (_, __) => const NewChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.createGroup,
        builder: (_, __) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: AppRoutes.groupInfo,
        builder: (_, state) => GroupInfoScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.call,
        builder: (_, state) => CallScreen(
          chatId: state.pathParameters['chatId']!,
          callData: state.extra as Map<String, dynamic>?,
        ),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
