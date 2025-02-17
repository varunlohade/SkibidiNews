import 'package:equatable/equatable.dart';

enum PodcastDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
}

class Podcast extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? localAudioPath;
  final String? remoteAudioUrl;
  final Duration duration;
  final DateTime publishedAt;
  final int listens;
  final bool isPopular;
  final List<String> tags;
  final PodcastDownloadStatus downloadStatus;
  final double? downloadProgress;

  const Podcast({
    required this.id,
    required this.title,
    required this.description,
    this.localAudioPath,
    this.remoteAudioUrl,
    required this.duration,
    required this.publishedAt,
    this.listens = 0,
    this.isPopular = false,
    required this.tags,
    this.downloadStatus = PodcastDownloadStatus.notDownloaded,
    this.downloadProgress,
  });

  Podcast copyWith({
    String? id,
    String? title,
    String? description,
    String? localAudioPath,
    String? remoteAudioUrl,
    Duration? duration,
    DateTime? publishedAt,
    int? listens,
    bool? isPopular,
    List<String>? tags,
    PodcastDownloadStatus? downloadStatus,
    double? downloadProgress,
  }) {
    return Podcast(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      remoteAudioUrl: remoteAudioUrl ?? this.remoteAudioUrl,
      duration: duration ?? this.duration,
      publishedAt: publishedAt ?? this.publishedAt,
      listens: listens ?? this.listens,
      isPopular: isPopular ?? this.isPopular,
      tags: tags ?? this.tags,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  bool get isDownloaded => downloadStatus == PodcastDownloadStatus.downloaded;
  bool get isDownloading => downloadStatus == PodcastDownloadStatus.downloading;
  String get audioSource {
    if (localAudioPath != null) {
      final path = localAudioPath!.startsWith('file://') 
          ? localAudioPath! 
          : 'file://${localAudioPath!}';
      print('Using local audio path: $path');
      return path;
    }
    if (remoteAudioUrl != null) {
      print('Using remote audio URL: $remoteAudioUrl');
      return remoteAudioUrl!;
    }
    return '';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        localAudioPath,
        remoteAudioUrl,
        duration,
        publishedAt,
        listens,
        isPopular,
        tags,
        downloadStatus,
        downloadProgress,
      ];
} 