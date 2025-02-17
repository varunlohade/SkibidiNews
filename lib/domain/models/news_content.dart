import 'package:equatable/equatable.dart';
import 'content_tag.dart';

class NewsContent extends Equatable {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final Duration duration;
  final List<ContentTag> tags;
  final DateTime publishedAt;
  final int listens;
  final bool isPopular;

  const NewsContent({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.duration,
    required this.tags,
    required this.publishedAt,
    this.listens = 0,
    this.isPopular = false,
  });

  @override
  List<Object?> get props => [id, title, description, audioUrl, duration, tags, publishedAt, listens, isPopular];
} 