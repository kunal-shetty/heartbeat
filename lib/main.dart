import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/supabase_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/chat/presentation/blocs/chat_list_bloc.dart';
// import 'shared/services/notification_service.dart';
// import 'shared/services/connectivity_service.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase
  // await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  // Setup dependency injection
  await di.init();

  // Initialize notification service
  // await di.sl<NotificationService>().initialize();

  runApp(const ChatterApp());
}

class ChatterApp extends StatelessWidget {
  const ChatterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()..add(AuthCheckStatusEvent())),
        BlocProvider<ChatListBloc>(create: (_) => di.sl<ChatListBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Heartbeat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        localizationsDelegates: const [
          // Add localization delegates if needed
        ],
      ),
    );
  }
}
