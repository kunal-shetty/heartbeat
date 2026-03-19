import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/sign_in_with_phone.dart';
import 'features/auth/domain/usecases/sign_in_with_google.dart';
import 'features/auth/domain/usecases/sign_in_with_email.dart';
import 'features/auth/domain/usecases/sign_up_with_email.dart';
import 'features/auth/domain/usecases/verify_otp.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';

import 'features/chat/data/datasources/chat_remote_datasource.dart';
import 'features/chat/data/datasources/chat_local_datasource.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/domain/usecases/get_chats.dart';
import 'features/chat/domain/usecases/send_message.dart';
import 'features/chat/domain/usecases/get_messages.dart';
import 'features/chat/domain/usecases/delete_message.dart';
import 'features/chat/presentation/blocs/chat_list_bloc.dart';
import 'features/chat/presentation/blocs/chat_bloc.dart';

import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/domain/usecases/get_profile.dart';
import 'features/profile/domain/usecases/update_profile.dart';
import 'features/profile/presentation/blocs/profile_bloc.dart';

// import 'shared/services/notification_service.dart';
import 'shared/services/storage_service.dart';
import 'shared/services/connectivity_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Supabase client
  sl.registerSingleton<SupabaseClient>(Supabase.instance.client);

  // Services
  // sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<StorageService>(() => StorageService(sl()));
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  // ── Auth ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SignInWithPhone(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => SignUpWithEmail(sl()));
  sl.registerLazySingleton(() => VerifyOtp(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerFactory(() => AuthBloc(
        signInWithPhone: sl(),
        signInWithGoogle: sl(),
        signInWithEmail: sl(),
        signUpWithEmail: sl(),
        verifyOtp: sl(),
        signOut: sl(),
        getCurrentUser: sl(),
      ));

  // ── Chat ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(sl()));
  // In-memory + SharedPreferences cache — no code generation required
  sl.registerLazySingleton<ChatLocalDataSource>(
      () => ChatLocalDataSourceImpl());
  sl.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(sl(), sl(), sl()));
  sl.registerLazySingleton(() => GetChats(sl()));
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => GetMessages(sl()));
  sl.registerLazySingleton(() => DeleteMessage(sl()));
  sl.registerFactory(() => ChatListBloc(getChats: sl()));
  sl.registerFactory(() => ChatBloc(
        sendMessage: sl(),
        getMessages: sl(),
        deleteMessage: sl(),
        chatRepository: sl(),
      ));

  // ── Profile ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerFactory(() => ProfileBloc(
        getProfile: sl(),
        updateProfile: sl(),
      ));
}
