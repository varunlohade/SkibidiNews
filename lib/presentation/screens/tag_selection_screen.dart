import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skibidinews/core/animations/page_transitions.dart';
import '../../domain/models/content_tag.dart';
import '../screens/home_screen.dart';

class TagSelectionScreen extends StatefulWidget {
  const TagSelectionScreen({super.key});

  @override
  State<TagSelectionScreen> createState() => _TagSelectionScreenState();
}

class _TagSelectionScreenState extends State<TagSelectionScreen> {
  final List<ContentTag> tags = [
    ContentTag(id: '1', name: 'News', emoji: '📰', isSelected: false),
    ContentTag(id: '2', name: 'Technology', emoji: '💻', isSelected: false),
    ContentTag(id: '3', name: 'Fashion', emoji: '👗', isSelected: false),
    ContentTag(id: '4', name: 'World', emoji: '🌍', isSelected: false),
    ContentTag(id: '5', name: 'Business', emoji: '💼', isSelected: false),
    ContentTag(id: '6', name: 'Entertainment', emoji: '🎬', isSelected: false),
    ContentTag(id: '7', name: 'Sports', emoji: '⚽', isSelected: false),
    ContentTag(id: '8', name: 'Music', emoji: '🎵', isSelected: false),
  ];

  final TextEditingController _tagController = TextEditingController();
  final Map<String, double> _tagScales = {};
  double _buttonScale = 1.0;

  @override
  void initState() {
    super.initState();
    for (var tag in tags) {
      _tagScales[tag.id] = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎧 Select Topics',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your interests',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Select topics to personalize your news feed',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTapDown: (_) => setState(() => _tagScales[tags[index].id] = 0.95),
                      onTapUp: (_) {
                        setState(() {
                          _tagScales[tags[index].id] = 1.0;
                          tags[index].isSelected = !tags[index].isSelected;
                        });
                      },
                      onTapCancel: () => setState(() => _tagScales[tags[index].id] = 1.0),
                      child: AnimatedScale(
                        scale: _tagScales[tags[index].id] ?? 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          decoration: BoxDecoration(
                            color: tags[index].isSelected ? Colors.black : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tags[index].emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tags[index].name,
                                  style: TextStyle(
                                    color: tags[index].isSelected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          hintText: 'Add custom topic...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _addCustomTag,
                      icon: const Icon(Icons.add_circle),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTapDown: (_) => setState(() => _buttonScale = 0.95),
                onTapUp: (_) => setState(() => _buttonScale = 1.0),
                onTapCancel: () => setState(() => _buttonScale = 1.0),
                child: AnimatedScale(
                  scale: _buttonScale,
                  duration: const Duration(milliseconds: 150),
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedTags = tags.where((tag) => tag.isSelected).toList();
                      if (selectedTags.isNotEmpty) {
                        Navigator.of(context).pushReplacement(
                          PageTransitions.slideUp(
                            page: HomeScreen(selectedTags: selectedTags),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addCustomTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        tags.add(ContentTag(
          id: DateTime.now().toString(),
          name: _tagController.text,
          emoji: '🎯',
        ));
        _tagController.clear();
      });
    }
  }
}
