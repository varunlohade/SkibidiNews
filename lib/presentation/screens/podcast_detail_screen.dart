import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/models/podcast.dart';
import '../bloc/audio/audio_bloc.dart';

class PodcastDetailScreen extends StatelessWidget {
  final Podcast podcast;

  const PodcastDetailScreen({
    super.key,
    required this.podcast,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildControls(context),
                _buildDescription(),
                _buildTags(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.purple.shade800,
                Colors.black,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.headphones,
              size: 120.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            podcast.title,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.headphones_outlined, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                '${podcast.listens} listens',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Icon(Icons.access_time, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                '${podcast.duration.inMinutes}:${(podcast.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<AudioBloc, AudioState>(
            builder: (context, state) {
              final isPlaying = state is AudioPlaying && 
                              state.currentUrl == podcast.audioSource;
              return CircleAvatar(
                radius: 32.r,
                backgroundColor: Colors.green,
                child: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32.sp,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      context.read<AudioBloc>().add(PauseAudio());
                    } else {
                      context.read<AudioBloc>().add(
                        PlayAudio(
                          podcast.audioSource,
                          title: podcast.title,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
          if (!podcast.isDownloaded)
            ElevatedButton.icon(
              onPressed: podcast.isDownloading ? null : () {
                // TODO: Implement download
              },
              icon: Icon(
                podcast.isDownloading ? Icons.download : Icons.download_outlined,
                size: 24.sp,
              ),
              label: Text(
                podcast.isDownloading ? 'Downloading...' : 'Download',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this episode',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            podcast.description,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: podcast.tags.map((tag) => Chip(
          label: Text(tag),
          backgroundColor: Colors.grey[200],
        )).toList(),
      ),
    );
  }
} 