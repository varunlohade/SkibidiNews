import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

// Events
abstract class AudioEvent extends Equatable {
  const AudioEvent();

  @override
  List<Object> get props => [];
}

class PlayAudio extends AudioEvent {
  final String url;
  final String title;
  final String? artist;
  
  const PlayAudio(this.url, {
    this.title = 'SkibiNews Podcast',
    this.artist = 'AI Host',
  });

  @override
  List<Object> get props => [url, title];
}

class PauseAudio extends AudioEvent {}
class ResumeAudio extends AudioEvent {}
class StopAudio extends AudioEvent {}
class SeekAudio extends AudioEvent {
  final Duration position;
  const SeekAudio(this.position);

  @override
  List<Object> get props => [position];
}

// States
abstract class AudioState extends Equatable {
  const AudioState();

  @override
  List<Object> get props => [];
}

class AudioInitial extends AudioState {}
class AudioLoading extends AudioState {}
class AudioPlaying extends AudioState {
  final Duration duration;
  final Duration position;
  final String currentUrl;
  final String title;

  const AudioPlaying({
    required this.duration,
    required this.position,
    required this.currentUrl,
    required this.title,
  });

  @override
  List<Object> get props => [duration, position, currentUrl, title];
}
class AudioPaused extends AudioState {
  final Duration position;
  final String currentUrl;
  final String title;

  const AudioPaused({
    required this.position,
    required this.currentUrl,
    required this.title,
  });

  @override
  List<Object> get props => [position, currentUrl, title];
}
class AudioStopped extends AudioState {}
class AudioError extends AudioState {
  final String message;
  const AudioError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentTitle;
  String? _currentUrl;
  
  AudioBloc() : super(AudioInitial()) {
    on<PlayAudio>(_onPlayAudio);
    on<PauseAudio>(_onPauseAudio);
    on<ResumeAudio>(_onResumeAudio);
    on<StopAudio>(_onStopAudio);
    on<SeekAudio>(_onSeekAudio);

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        add(StopAudio());
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      if (state is AudioPlaying && _currentUrl != null && _currentTitle != null) {
        emit(AudioPlaying(
          duration: _audioPlayer.duration ?? Duration.zero,
          position: position,
          currentUrl: _currentUrl!,
          title: _currentTitle!,
        ));
      }
    });
  }

  Future<void> _onPlayAudio(PlayAudio event, Emitter<AudioState> emit) async {
    try {
      emit(AudioLoading());
      
      // Set audio source with metadata for background playback
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(event.url),
          tag: MediaItem(
            id: event.url,
            album: 'SkibiNews',
            title: event.title,
            artist: event.artist,
          ),
        ),
      );
      
      _currentUrl = event.url;
      _currentTitle = event.title;
      
      await _audioPlayer.play();
      
      emit(AudioPlaying(
        duration: _audioPlayer.duration ?? Duration.zero,
        position: _audioPlayer.position,
        currentUrl: event.url,
        title: event.title,
      ));
    } catch (e) {
      emit(AudioError(e.toString()));
    }
  }

  Future<void> _onPauseAudio(PauseAudio event, Emitter<AudioState> emit) async {
    if (_currentUrl != null && _currentTitle != null) {
      await _audioPlayer.pause();
      emit(AudioPaused(
        position: _audioPlayer.position,
        currentUrl: _currentUrl!,
        title: _currentTitle!,
      ));
    }
  }

  Future<void> _onResumeAudio(ResumeAudio event, Emitter<AudioState> emit) async {
    if (_currentUrl != null && _currentTitle != null) {
      await _audioPlayer.play();
      emit(AudioPlaying(
        duration: _audioPlayer.duration ?? Duration.zero,
        position: _audioPlayer.position,
        currentUrl: _currentUrl!,
        title: _currentTitle!,
      ));
    }
  }

  Future<void> _onStopAudio(StopAudio event, Emitter<AudioState> emit) async {
    await _audioPlayer.stop();
    _currentUrl = null;
    _currentTitle = null;
    emit(AudioStopped());
  }

  Future<void> _onSeekAudio(SeekAudio event, Emitter<AudioState> emit) async {
    if (_currentUrl != null && _currentTitle != null) {
      await _audioPlayer.seek(event.position);
      emit(AudioPlaying(
        duration: _audioPlayer.duration ?? Duration.zero,
        position: event.position,
        currentUrl: _currentUrl!,
        title: _currentTitle!,
      ));
    }
  }

  @override
  Future<void> close() {
    _audioPlayer.dispose();
    return super.close();
  }
} 