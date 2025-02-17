import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'presentation/screens/authentication_screen.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/audio/audio_bloc.dart';
import 'presentation/bloc/podcast/podcast_bloc.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/openai_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize background playback
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.skibidinews.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );

    // Initialize audio session
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  } catch (e) {
    debugPrint('Error initializing audio session: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize OpenAI repository with your API key
    final openAIRepository = OpenAIRepository(apiKey: "");

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X dimensions as base
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(
                authRepository: AuthRepositoryImpl(),
              ),
            ),
            BlocProvider<AudioBloc>(
              create: (context) => AudioBloc(),
            ),
            BlocProvider<PodcastBloc>(
              create: (context) => PodcastBloc(
                openAIRepository: openAIRepository,
              ),
            ),
          ],
          child: MaterialApp(
            title: 'Gen Alpha Auth',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.black,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.spaceGroteskTextTheme(),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            home: const AuthenticationScreen(),
          ),
        );
      },
    );
  }
}
