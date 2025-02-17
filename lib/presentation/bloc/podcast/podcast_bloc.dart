import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/openai_repository.dart';
import '../../../domain/models/podcast.dart';

// Events
abstract class PodcastEvent extends Equatable {
  const PodcastEvent();

  @override
  List<Object> get props => [];
}

class GeneratePodcast extends PodcastEvent {
  final String topic;
  const GeneratePodcast(this.topic);

  @override
  List<Object> get props => [topic];
}

class DownloadPodcast extends PodcastEvent {
  final Podcast podcast;
  const DownloadPodcast(this.podcast);

  @override
  List<Object> get props => [podcast];
}

// States
abstract class PodcastState extends Equatable {
  const PodcastState();

  @override
  List<Object> get props => [];
}

class PodcastInitial extends PodcastState {}

class PodcastGenerating extends PodcastState {
  final String status;
  const PodcastGenerating(this.status);

  @override
  List<Object> get props => [status];
}

class PodcastGenerated extends PodcastState {
  final Podcast podcast;
  const PodcastGenerated(this.podcast);

  @override
  List<Object> get props => [podcast];
}

class PodcastDownloading extends PodcastState {
  final Podcast podcast;
  final double progress;
  
  const PodcastDownloading(this.podcast, this.progress);

  @override
  List<Object> get props => [podcast, progress];
}

class PodcastDownloaded extends PodcastState {
  final Podcast podcast;
  const PodcastDownloaded(this.podcast);

  @override
  List<Object> get props => [podcast];
}

class PodcastError extends PodcastState {
  final String message;
  const PodcastError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class PodcastBloc extends Bloc<PodcastEvent, PodcastState> {
  final OpenAIRepository openAIRepository;

  PodcastBloc({required this.openAIRepository}) : super(PodcastInitial()) {
    on<GeneratePodcast>(_onGeneratePodcast);
    on<DownloadPodcast>(_onDownloadPodcast);
  }

  Future<void> _onGeneratePodcast(
    GeneratePodcast event,
    Emitter<PodcastState> emit,
  ) async {
    try {
      emit(const PodcastGenerating('Generating podcast content...'));
      final content = await openAIRepository.generatePodcastContent(event.topic);
      
      emit(const PodcastGenerating('Creating dual-voice audio...'));
      final audioPath = await openAIRepository.generateDualVoicePodcast(event.topic);
      
      print('Generated audio path: $audioPath');
      
      final podcast = Podcast(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Podcast: ${event.topic}',
        description: content['content']!,
        localAudioPath: audioPath,
        remoteAudioUrl: null,
        duration: const Duration(minutes: 2), // Placeholder duration
        publishedAt: DateTime.now(),
        tags: ['AI Generated', event.topic],
        downloadStatus: PodcastDownloadStatus.downloaded,
      );
      
      emit(PodcastGenerated(podcast));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  Future<void> _onDownloadPodcast(
    DownloadPodcast event,
    Emitter<PodcastState> emit,
  ) async {
    try {
      final podcast = event.podcast.copyWith(
        downloadStatus: PodcastDownloadStatus.downloading,
        downloadProgress: 0.0,
      );
      
      emit(PodcastDownloading(podcast, 0.0));
      
      final localPath = await openAIRepository.downloadPodcast(
        podcast.remoteAudioUrl!,
        'podcast_${podcast.id}.mp3',
      );
      
      final downloadedPodcast = podcast.copyWith(
        localAudioPath: localPath,
        downloadStatus: PodcastDownloadStatus.downloaded,
        downloadProgress: 1.0,
      );
      
      emit(PodcastDownloaded(downloadedPodcast));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }
} 