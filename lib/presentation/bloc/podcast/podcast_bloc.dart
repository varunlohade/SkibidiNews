import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/openai_repository.dart';

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
  final String audioPath;
  final String topic;
  final String content;

  const PodcastGenerated({
    required this.audioPath,
    required this.topic,
    required this.content,
  });

  @override
  List<Object> get props => [audioPath, topic, content];
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
  }

  Future<void> _onGeneratePodcast(
    GeneratePodcast event,
    Emitter<PodcastState> emit,
  ) async {
    try {
      emit(const PodcastGenerating('Generating podcast content...'));
      final content = await openAIRepository.generatePodcastContent(event.topic);
      
      emit(const PodcastGenerating('Converting to audio...'));
      final audioPath = await openAIRepository.generateAudio(content);
      
      emit(PodcastGenerated(
        audioPath: audioPath,
        topic: event.topic,
        content: content,
      ));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }
} 