class ContentTag {
  final String id;
  final String name;
  final String emoji;
  bool isSelected;

  ContentTag({
    required this.id,
    required this.name,
    required this.emoji,
    this.isSelected = false,
  });
} 