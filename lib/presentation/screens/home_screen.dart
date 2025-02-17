import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/models/content_tag.dart';
import '../../domain/models/podcast.dart';
import '../bloc/audio/audio_bloc.dart';
import '../bloc/podcast/podcast_bloc.dart';
import 'podcast_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<ContentTag> selectedTags;

  const HomeScreen({
    super.key,
    required this.selectedTags,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Podcast> _recentPodcasts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    '🎧 SkibiNews',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showGeneratePodcastDialog(context),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'For You'),
                Tab(text: 'Trending'),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  TabBarView(
                    controller: _tabController,
                    children: [
                      _buildForYouTab(),
                      _buildTrendingTab(),
                    ],
                  ),
                  BlocBuilder<PodcastBloc, PodcastState>(
                    builder: (context, state) {
                      if (state is PodcastGenerating) {
                        return Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  state.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            BlocListener<PodcastBloc, PodcastState>(
              listener: (context, state) {
                if (state is PodcastGenerated) {
                  context.read<AudioBloc>().add(
                        PlayAudio(
                          state.podcast.audioSource,
                          title: state.podcast.title,
                        ),
                      );

                  setState(() {
                    _recentPodcasts.insert(0, state.podcast);
                  });

                  // Navigate to podcast detail screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PodcastDetailScreen(
                        podcast: state.podcast,
                      ),
                    ),
                  );
                } else if (state is PodcastError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              child: BlocBuilder<AudioBloc, AudioState>(
                builder: (context, state) {
                  if (state is AudioPlaying) {
                    return _buildMiniPlayer();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGeneratePodcastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate New Podcast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a topic to generate a podcast about:'),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _buildTopicChip('Iran vs US Wars'),
                _buildTopicChip('AI & Blockchain'),
                _buildTopicChip('Future of Tech'),
                _buildTopicChip('Crypto News'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicChip(String topic) {
    return ActionChip(
      label: Text(topic),
      onPressed: () {
        context.read<PodcastBloc>().add(GeneratePodcast(topic));
        Navigator.pop(context);
      },
    );
  }

  Widget _buildForYouTab() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Text(
          'Recent Drops',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        if (_recentPodcasts.isEmpty)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 32.h),
                const Icon(
                  Icons.podcasts,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No podcasts yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Tap + to generate a new podcast',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(
            _recentPodcasts.length,
            (index) {
              final podcast = _recentPodcasts[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: _buildPodcastCard(podcast),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTrendingTab() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Text(
          'Popular Now',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        if (_recentPodcasts.isNotEmpty)
          _buildPodcastCard(_recentPodcasts.first.copyWith(isPopular: true)),
      ],
    );
  }

  Widget _buildPodcastCard(Podcast podcast) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PodcastDetailScreen(podcast: podcast),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (podcast.isPopular)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '🔥 Trending',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  '👂 ${podcast.listens}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              podcast.title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Text(
                  '🎧 ${podcast.duration.inMinutes}:${(podcast.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                ...podcast.tags.map((tag) => Padding(
                      padding: EdgeInsets.only(right: 4.w),
                      child: Chip(
                        label: Text(tag),
                        padding: EdgeInsets.zero,
                        labelStyle: TextStyle(fontSize: 10.sp),
                      ),
                    )),
                const Spacer(),
                BlocBuilder<AudioBloc, AudioState>(
                  builder: (context, state) {
                    if (state is AudioPlaying && state.title == podcast.title) {
                      return IconButton(
                        icon: const Icon(Icons.pause_circle_filled),
                        onPressed: () {
                          context.read<AudioBloc>().add(PauseAudio());
                        },
                      );
                    }
                    return IconButton(
                      icon: const Icon(Icons.play_circle_filled),
                      onPressed: () {
                        context.read<AudioBloc>().add(
                              PlayAudio(
                                podcast.audioSource,
                                title: podcast.title,
                              ),
                            );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        if (state is! AudioPlaying) return const SizedBox.shrink();

        return Container(
          height: 64.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.headphones,
                color: Colors.white,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Now Playing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      state.title,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.pause, color: Colors.white),
                onPressed: () {
                  context.read<AudioBloc>().add(PauseAudio());
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.white),
                onPressed: () {
                  context.read<AudioBloc>().add(StopAudio());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
