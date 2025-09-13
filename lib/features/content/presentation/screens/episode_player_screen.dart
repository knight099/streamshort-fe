// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import '../../data/models/content_models.dart';
// import '../../../auth/presentation/providers/auth_providers.dart';
// import '../../data/providers.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'dart:async';

// class EpisodePlayerScreen extends ConsumerStatefulWidget {
//   final String episodeId;
//   final String seriesId;

//   const EpisodePlayerScreen({super.key, required this.episodeId, required this.seriesId});

//   @override
//   ConsumerState<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
// }

// class _EpisodePlayerScreenState extends ConsumerState<EpisodePlayerScreen> {
//   late final PageController _pageController;
//   final Map<int, VideoPlayerController> _controllers = {};
//   int _currentIndex = 0;
//   bool _isMuted = true;
//   bool _isManuallyPaused = false;
//   Series? _series;
//   List<Episode> _episodes = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadSeriesData();
//   }

//   Future<void> _loadSeriesData() async {
//     try {
//       final contentRepository = ref.read(contentRepositoryProvider);
//       final authUser = ref.read(authUserProvider);
      
//       final series = await contentRepository.getSeriesDetail(
//         seriesId: widget.seriesId,
//         accessToken: authUser?.accessToken,
//       );
      
//       if (mounted) {
//         setState(() {
//           _series = series;
//           _episodes = series.episodes ?? [];
//           _isLoading = false;
//         });
        
//         if (_episodes.isNotEmpty) {
//           _currentIndex = _episodes.indexWhere((e) => e.id == widget.episodeId);
//           if (_currentIndex == -1) _currentIndex = 0;
          
//           _pageController = PageController(initialPage: _currentIndex);
//           _prepareControllers(_currentIndex);
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load series: $e')),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     for (final controller in _controllers.values) {
//       controller.dispose();
//     }
//     _controllers.clear();
//     super.dispose();
//   }

//   Future<void> _prepareControllers(int centerIndex) async {
//     if (_episodes.isEmpty) return;
    
//     final List<int> needed = [centerIndex];
//     if (centerIndex > 0) needed.add(centerIndex - 1);
//     if (centerIndex < _episodes.length - 1) needed.add(centerIndex + 1);

//     for (final index in needed) {
//       if (index < _episodes.length && !_controllers.containsKey(index)) {
//         await _createController(index);
//       }
//     }

//     // Dispose controllers that are far from current index
//     final toDispose = <int>[];
//     for (final key in _controllers.keys) {
//       if ((key - centerIndex).abs() > 1) {
//         toDispose.add(key);
//       }
//     }
//     for (final key in toDispose) {
//       _controllers[key]?.dispose();
//       _controllers.remove(key);
//     }
//   }

//   Future<void> _createController(int index) async {
//     if (index >= _episodes.length) return;

//     final episode = _episodes[index];
//     // Use episode's video URL or fallback to demo video
//     final videoUrl = episode.hlsManifestUrl ?? 
//                     'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    
//     final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
//     await controller.initialize();
//     controller.setLooping(true);
//     controller.setVolume(_isMuted ? 0.0 : 1.0);
    
//     if (index == _currentIndex) {
//       controller.play();
//     }
    
//     _controllers[index] = controller;
//   }


//   void _onPageChanged(int index) {
//     if (_currentIndex != index) {
//       // Pause current video
//       _controllers[_currentIndex]?.pause();
      
//       setState(() {
//         _currentIndex = index;
//       });
      
//       // Play new video
//       _controllers[index]?.play();
      
//       // Prepare nearby controllers
//       _prepareControllers(index);
//     }
//   }

//   void _togglePlayPause() {
//     final controller = _controllers[_currentIndex];
//     if (controller != null) {
//       if (controller.value.isPlaying) {
//         controller.pause();
//         setState(() {
//           _isManuallyPaused = true;
//         });
//       } else {
//         controller.play();
//         setState(() {
//           _isManuallyPaused = false;
//         });
//       }
//     }
//   }

//   void _toggleMute() {
//     setState(() {
//       _isMuted = !_isMuted;
//     });
    
//     for (final controller in _controllers.values) {
//       controller.setVolume(_isMuted ? 0.0 : 1.0);
//     }
//   }

//   void _navigateToEpisode(int direction) {
//     final newIndex = _currentIndex + direction;
    
//     if (newIndex >= 0 && newIndex < _episodes.length) {
//       _pageController.animateToPage(
//         newIndex,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child: CircularProgressIndicator(color: Colors.white),
//         ),
//       );
//     }
    
//     if (_episodes.isEmpty) {
//       return Scaffold(
//         backgroundColor: Colors.black,
//         body: const Center(
//           child: Text(
//             'No episodes available',
//             style: TextStyle(color: Colors.white, fontSize: 18),
//           ),
//         ),
//       );
//     }
    
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Video Player Pages
//           PageView.builder(
//             controller: _pageController,
//             onPageChanged: _onPageChanged,
//             scrollDirection: Axis.vertical,
//             itemCount: _episodes.length,
//             itemBuilder: (context, index) {
//               return _buildVideoPage(_episodes[index], index);
//             },
//           ),
          
//           // Top Controls
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             child: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       onPressed: () => Navigator.pop(context),
//                       icon: const Icon(Icons.arrow_back, color: Colors.white),
//                     ),
//                     const Spacer(),
//                     IconButton(
//                       onPressed: _toggleMute,
//                       icon: Icon(
//                         _isMuted ? Icons.volume_off : Icons.volume_up,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
          
//           // Bottom Controls
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Episode Info
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: Colors.black54,
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         _episodes[_currentIndex].title ?? 'Episode ${_currentIndex + 1}',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
                    
//                     // Navigation Controls
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         IconButton(
//                           onPressed: _currentIndex > 0 ? () => _navigateToEpisode(-1) : null,
//                           icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
//                         ),
//                         IconButton(
//                           onPressed: _togglePlayPause,
//                           icon: Icon(
//                             _controllers[_currentIndex]?.value.isPlaying == true
//                                 ? Icons.pause
//                                 : Icons.play_arrow,
//                             color: Colors.white,
//                             size: 48,
//                           ),
//                         ),
//                         IconButton(
//                           onPressed: _currentIndex < _episodes.length - 1 ? () => _navigateToEpisode(1) : null,
//                           icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
//                         ),
//                       ],
//                     ),
                    
//                     // Episode Counter
//                     const SizedBox(height: 8),
//                     Text(
//                       '${_currentIndex + 1} / ${_episodes.length}',
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildVideoPage(Episode episode, int index) {
//     final controller = _controllers[index];
    
//     return GestureDetector(
//       onTap: _togglePlayPause,
//       child: Container(
//         width: double.infinity,
//         height: double.infinity,
//         color: Colors.black,
//         child: controller != null && controller.value.isInitialized
//             ? Stack(
//                 children: [
//                   Center(
//                     child: AspectRatio(
//                       aspectRatio: controller.value.aspectRatio,
//                       child: VideoPlayer(controller),
//                     ),
//                   ),
                  
//                   // Loading indicator
//                   if (controller.value.isBuffering)
//                     const Center(
//                       child: CircularProgressIndicator(color: Colors.white),
//                     ),
                  
//                   // Play/Pause overlay
//                   if (!controller.value.isPlaying && !controller.value.isBuffering)
//                     const Center(
//                       child: Icon(
//                         Icons.play_arrow,
//                         color: Colors.white,
//                         size: 80,
//                       ),
//                     ),
//                 ],
//               )
//             : const Center(
//                 child: CircularProgressIndicator(color: Colors.white),
//               ),
//       ),
//     );
//   }
// }


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _EpisodePlayerScreenState extends ConsumerState<EpisodePlayerScreen> 
    with TickerProviderStateMixin {
  PageController? _pageController;
  final Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;
  bool _isMuted = false;
  bool _isManuallyPaused = false;
  bool _showControls = false;
  Timer? _controlsTimer;
  Series? _series;
  List<Episode> _episodes = [];
  bool _isLoading = true;
  double _currentVolume = 1.0;
  bool _isLiked = false;
  bool _isBookmarked = false;
  
  // Animation controllers
  AnimationController? _controlsAnimationController;
  AnimationController? _likeAnimationController;
  AnimationController? _volumeAnimationController;
  Animation<double>? _controlsOpacity;
  Animation<double>? _likeScale;
  Animation<double>? _volumeScale;
  
  // Gesture handling
  bool _isDragging = false;
  double _dragStartY = 0;
  double _currentPosition = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSeriesData();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _initializeAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _volumeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _controlsOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController!,
      curve: Curves.easeInOut,
    ));

    _likeScale = Tween<double>(
      begin: 0.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController!,
      curve: Curves.elasticOut,
    ));

    _volumeScale = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _volumeAnimationController!,
      curve: Curves.easeInOut,
    ));
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
        _showSnackBar('Failed to load series: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitDown,
    ]);
    
    _pageController?.dispose();
    _controlsTimer?.cancel();
    _controlsAnimationController?.dispose();
    _likeAnimationController?.dispose();
    _volumeAnimationController?.dispose();
    
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
    final videoUrl = episode.hlsManifestUrl ?? 
                    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await controller.initialize();
    controller.setLooping(true);
    controller.setVolume(_isMuted ? 0.0 : _currentVolume);
    
    if (index == _currentIndex && !_isManuallyPaused) {
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
        _isManuallyPaused = false;
      });
      
      // Play new video
      if (!_isManuallyPaused) {
        _controllers[index]?.play();
      }
      
      // Prepare nearby controllers
      _prepareControllers(index);
      
      // Hide controls
      _hideControls();
      
      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _togglePlayPause() {
    final controller = _controllers[_currentIndex];
    if (controller != null) {
      HapticFeedback.selectionClick();
      
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
    HapticFeedback.lightImpact();
    setState(() {
      _isMuted = !_isMuted;
    });
    
    _volumeAnimationController?.forward().then((_) {
      _volumeAnimationController?.reverse();
    });
    
    for (final controller in _controllers.values) {
      controller.setVolume(_isMuted ? 0.0 : _currentVolume);
    }
  }

  void _toggleLike() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLiked = !_isLiked;
    });
    
    if (_isLiked) {
      _likeAnimationController?.forward().then((_) {
        _likeAnimationController?.reverse();
      });
    }
    
    _showSnackBar(
      _isLiked ? 'Added to favorites' : 'Removed from favorites',
      isError: false,
    );
  }

  void _toggleBookmark() {
    HapticFeedback.lightImpact();
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    
    _showSnackBar(
      _isBookmarked ? 'Added to watchlist' : 'Removed from watchlist',
      isError: false,
    );
  }

  void _showControlsMethod() {
    setState(() {
      _showControls = true;
    });
    _controlsAnimationController?.forward();
    
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      _hideControls();
    });
  }

  void _hideControls() {
    if (_showControls) {
      _controlsAnimationController?.reverse();
      setState(() {
        _showControls = false;
      });
    }
    _controlsTimer?.cancel();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      ),
    );
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _isDragging = true;
    _dragStartY = details.localPosition.dy;
    _currentPosition = 0;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    setState(() {
      _currentPosition = details.localPosition.dy - _dragStartY;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    
    _isDragging = false;
    final velocity = details.velocity.pixelsPerSecond.dy;
    
    if (velocity.abs() > 500 || _currentPosition.abs() > 100) {
      if (velocity > 0 || _currentPosition > 0) {
        // Swipe down - previous episode
        if (_currentIndex > 0) {
          _pageController?.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else {
        // Swipe up - next episode
        if (_currentIndex < _episodes.length - 1) {
          _pageController?.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    }
    
    setState(() {
      _currentPosition = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }
    
    if (_episodes.isEmpty) {
      return _buildEmptyScreen();
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Player Pages
          GestureDetector(
            onTap: () {
              if (_showControls) {
                _hideControls();
              } else {
                _showControlsMethod();
              }
            },
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: Transform.translate(
              offset: Offset(0, _currentPosition * 0.3),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                scrollDirection: Axis.vertical,
                itemCount: _episodes.length,
                itemBuilder: (context, index) {
                  return _buildVideoPage(_episodes[index], index);
                },
              ),
            ),
          ),
          
          // Side Actions Panel
          Positioned(
            right: 16,
            bottom: 120,
            child: _buildSideActions(),
          ),
          
          // Episode Info Overlay
          Positioned(
            left: 16,
            right: 80,
            bottom: 120,
            child: _buildEpisodeInfo(),
          ),
          
          // Top Controls
          AnimatedBuilder(
            animation: _controlsOpacity!,
            builder: (context, child) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _controlsOpacity!.value,
                  child: _buildTopControls(),
                ),
              );
            },
          ),
          
          // Bottom Progress Indicator
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildProgressIndicator(),
          ),
          
          // Volume Indicator
          if (_showControls)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).size.height * 0.4,
              child: AnimatedBuilder(
                animation: _volumeScale!,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _volumeScale!.value,
                    child: _buildVolumeIndicator(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading episodes...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_library_outlined,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No episodes available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later for new content',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPage(Episode episode, int index) {
    final controller = _controllers[index];
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: controller != null && controller.value.isInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Video Player
                Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
                
                // Loading indicator
                if (controller.value.isBuffering)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                
                // Play/Pause overlay with animation
                if (!controller.value.isPlaying && !controller.value.isBuffering && _showControls)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                
                // Double tap like animation
                AnimatedBuilder(
                  animation: _likeScale!,
                  builder: (context, child) {
                    return _likeScale!.value > 0
                        ? Center(
                            child: Transform.scale(
                              scale: _likeScale!.value,
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 80,
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Loading ${episode.title ?? "Episode"}...',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTopControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isMuted ? 'Muted' : '${(_currentVolume * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideActions() {
    return Column(
      children: [
        _buildActionButton(
          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
          color: _isLiked ? Colors.red : Colors.white,
          onTap: _toggleLike,
          count: '1.2K',
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          color: _isBookmarked ? Colors.amber : Colors.white,
          onTap: _toggleBookmark,
          count: '234',
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          icon: Icons.share,
          color: Colors.white,
          onTap: () {
            HapticFeedback.lightImpact();
            _showSnackBar('Share feature coming soon!', isError: false);
          },
          count: '89',
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          icon: _isMuted ? Icons.volume_off : Icons.volume_up,
          color: Colors.white,
          onTap: _toggleMute,
          count: null,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? count,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Center(
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        if (count != null) ...[
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEpisodeInfo() {
    final episode = _episodes[_currentIndex];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_series?.title != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.blue],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _series!.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          episode.title ?? 'Episode ${_currentIndex + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (_series?.synopsis != null) ...[
          const SizedBox(height: 4),
          Text(
            _series!.synopsis!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Episode ${_currentIndex + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_currentIndex + 1} of ${_episodes.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ...List.generate(_episodes.length, (index) {
                final isActive = index == _currentIndex;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: 3,
                    decoration: BoxDecoration(
                      color: isActive 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isMuted ? Icons.volume_off : Icons.volume_up,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 8),
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 4,
                height: _isMuted ? 0 : 60 * _currentVolume,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}