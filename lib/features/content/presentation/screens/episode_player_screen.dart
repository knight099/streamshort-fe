import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/content_models.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class EpisodePlayerScreen extends ConsumerStatefulWidget {
  final String episodeId;
  final String seriesId;

  const EpisodePlayerScreen({super.key, required this.episodeId, required this.seriesId});

  @override
  ConsumerState<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends ConsumerState<EpisodePlayerScreen> {
  late final PageController _pageController;
  final Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;
  bool _isMuted = true;
  bool _isManuallyPaused = false;
  Series? _series;
  List<Episode> _episodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeriesData();
  }

  Future<void> _loadSeriesData() async {
    try {
      final contentRepository = ref.read(contentRepositoryProvider);
      final authUser = ref.read(authUserProvider);
      
      final series = await contentRepository.getSeriesDetail(
        seriesId: widget.seriesId,
        accessToken: authUser?.accessToken,
      );
      
      if (mounted) {
        setState(() {
          _series = series;
          _episodes = series.episodes ?? [];
          _isLoading = false;
        });
        
        if (_episodes.isNotEmpty) {
          _currentIndex = _episodes.indexWhere((e) => e.id == widget.episodeId);
          if (_currentIndex == -1) _currentIndex = 0;
          
          _pageController = PageController(initialPage: _currentIndex);
          _prepareControllers(_currentIndex);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load series: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  Future<void> _prepareControllers(int centerIndex) async {
    if (_episodes.isEmpty) return;
    
    final List<int> needed = [centerIndex];
    if (centerIndex > 0) needed.add(centerIndex - 1);
    if (centerIndex < _episodes.length - 1) needed.add(centerIndex + 1);

    for (final index in needed) {
      if (index < _episodes.length && !_controllers.containsKey(index)) {
        await _createController(index);
      }
    }

    // Dispose controllers that are far from current index
    final toDispose = <int>[];
    for (final key in _controllers.keys) {
      if ((key - centerIndex).abs() > 1) {
        toDispose.add(key);
      }
    }
    for (final key in toDispose) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
    }
  }

  Future<void> _createController(int index) async {
    if (index >= _episodes.length) return;

    final episode = _episodes[index];
    // Use episode's video URL or fallback to demo video
    final videoUrl = episode.hlsManifestUrl ?? 
                    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await controller.initialize();
    controller.setLooping(true);
    controller.setVolume(_isMuted ? 0.0 : 1.0);
    
    if (index == _currentIndex) {
      controller.play();
    }
    
    _controllers[index] = controller;
  }


  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      // Pause current video
      _controllers[_currentIndex]?.pause();
      
      setState(() {
        _currentIndex = index;
      });
      
      // Play new video
      _controllers[index]?.play();
      
      // Prepare nearby controllers
      _prepareControllers(index);
    }
  }

  void _togglePlayPause() {
    final controller = _controllers[_currentIndex];
    if (controller != null) {
      if (controller.value.isPlaying) {
        controller.pause();
        setState(() {
          _isManuallyPaused = true;
        });
      } else {
        controller.play();
        setState(() {
          _isManuallyPaused = false;
        });
      }
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    
    for (final controller in _controllers.values) {
      controller.setVolume(_isMuted ? 0.0 : 1.0);
    }
  }

  void _navigateToEpisode(int direction) {
    final newIndex = _currentIndex + direction;
    
    if (newIndex >= 0 && newIndex < _episodes.length) {
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    if (_episodes.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'No episodes available',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Player Pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            scrollDirection: Axis.vertical,
            itemCount: _episodes.length,
            itemBuilder: (context, index) {
              return _buildVideoPage(_episodes[index], index);
            },
          ),
          
          // Top Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _toggleMute,
                      icon: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Episode Info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _episodes[_currentIndex].title ?? 'Episode ${_currentIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Navigation Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: _currentIndex > 0 ? () => _navigateToEpisode(-1) : null,
                          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
                        ),
                        IconButton(
                          onPressed: _togglePlayPause,
                          icon: Icon(
                            _controllers[_currentIndex]?.value.isPlaying == true
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        IconButton(
                          onPressed: _currentIndex < _episodes.length - 1 ? () => _navigateToEpisode(1) : null,
                          icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                    
                    // Episode Counter
                    const SizedBox(height: 8),
                    Text(
                      '${_currentIndex + 1} / ${_episodes.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPage(Episode episode, int index) {
    final controller = _controllers[index];
    
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: controller != null && controller.value.isInitialized
            ? Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  ),
                  
                  // Loading indicator
                  if (controller.value.isBuffering)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  
                  // Play/Pause overlay
                  if (!controller.value.isPlaying && !controller.value.isBuffering)
                    const Center(
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
      ),
    );
  }
}