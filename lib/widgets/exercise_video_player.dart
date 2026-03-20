import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/exercise.dart';

class ExerciseVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final MuscleGroup? muscleGroup;

  const ExerciseVideoPlayer({
    super.key,
    this.videoUrl,
    this.muscleGroup,
  });

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Initialize video player if URL is provided
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      print('📹 Initializing video player with URL: ${widget.videoUrl}');
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl!),
      );

      print('⏳ Waiting for video to initialize...');
      await _videoController!.initialize();
      print('✅ Video controller initialized successfully');
      print('   Video size: ${_videoController!.value.size}');
      print('   Duration: ${_videoController!.value.duration}');

      if (mounted) {
        print('📦 Creating Chewie controller...');
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: true,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF3B82F6),
            handleColor: const Color(0xFF3B82F6),
            backgroundColor: Colors.grey,
            bufferedColor: Colors.grey.shade300,
          ),
        );
        print('✅ Chewie controller created');
        print('   _chewieController is null: ${_chewieController == null}');

        print('🔄 Calling setState to trigger rebuild');
        setState(() {
          _videoInitialized = true;
          print('   _videoInitialized set to true');
        });
        print('✅ setState complete, widget should rebuild');
      } else {
        print('⚠️ Widget not mounted after initialization');
      }
    } catch (e) {
      print('❌ Error initializing video: $e');
      print('   Stack trace: $e');
      if (mounted) {
        setState(() {
          _videoInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ ExerciseVideoPlayer.build() called');
    print('   videoUrl: ${widget.videoUrl}');
    print('   _videoInitialized: $_videoInitialized');
    print('   _chewieController: $_chewieController');

    // Show video if available and initialized
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      print('✅ Video URL is present, checking initialization status...');
      if (_videoInitialized && _chewieController != null) {
        print('🎬 DISPLAYING CHEWIE VIDEO PLAYER');
        return Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Chewie(
            controller: _chewieController!,
          ),
        );
      } else {
        // Still loading
        print('⏳ Video is loading... (initialized: $_videoInitialized, controller: ${_chewieController != null})');
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF3B82F6),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading video...',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }
    }

    // No video URL - show animation fallback
    print('ℹ️ No video URL provided, using animation');
    return _buildAnimationFallback();
  }

  Widget _buildAnimationFallback() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final progress = _animationController.value;

          // Select animation based on muscle group
          Widget animation;
          String exerciseLabel;

          switch (widget.muscleGroup) {
            case MuscleGroup.chest:
              animation = _buildChestAnimation(progress);
              exerciseLabel = 'Chest Exercise';
              break;
            case MuscleGroup.back:
              animation = _buildBackAnimation(progress);
              exerciseLabel = 'Back Exercise';
              break;
            case MuscleGroup.shoulders:
              animation = _buildShouldersAnimation(progress);
              exerciseLabel = 'Shoulder Exercise';
              break;
            case MuscleGroup.arms:
              animation = _buildArmsAnimation(progress);
              exerciseLabel = 'Arm Exercise';
              break;
            case MuscleGroup.legs:
              animation = _buildLegsAnimation(progress);
              exerciseLabel = 'Leg Exercise';
              break;
            case MuscleGroup.core:
              animation = _buildCoreAnimation(progress);
              exerciseLabel = 'Core Exercise';
              break;
            case MuscleGroup.cardio:
              animation = _buildCardioAnimation(progress);
              exerciseLabel = 'Cardio Exercise';
              break;
            case MuscleGroup.fullBody:
              animation = _buildFullBodyAnimation(progress);
              exerciseLabel = 'Full Body Exercise';
              break;
            default:
              animation = _buildArmsAnimation(progress);
              exerciseLabel = 'Exercise Demo';
          }

          return Stack(
            children: [
              // Animated background gradient
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A1A1A),
                      Color.lerp(
                        const Color(0xFF3B82F6).withOpacity(0.2),
                        const Color(0xFF8B5CF6).withOpacity(0.2),
                        progress,
                      )!,
                      const Color(0xFF0A0A0A),
                    ],
                  ),
                ),
              ),
              // Exercise animation
              Center(
                child: SizedBox(
                  height: 140,
                  child: animation,
                ),
              ),
              // Motion particles
              ...List.generate(3, (index) {
                final offset = (progress + index * 0.33) % 1.0;
                return Positioned(
                  top: 20 + (offset * 100),
                  left: 40 + (index * 15),
                  child: Opacity(
                    opacity: 1 - offset,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          const Color(0xFF3B82F6),
                          const Color(0xFF8B5CF6),
                          offset,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Rep counter badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Rep: ${(progress * 10).floor() + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Exercise label
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        size: 16,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        exerciseLabel,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChestAnimation(double progress) {
    final pushDepth = (1 - (progress * 2 - 1).abs()) * 15;
    return _buildExerciseFigure(
      progress: progress,
      verticalOffset: pushDepth,
      armAngle: (1 - (progress * 2 - 1).abs()) * 1.2,
      label: 'Chest Exercise',
    );
  }

  Widget _buildBackAnimation(double progress) {
    final pullHeight = (progress * 2 - 1).abs() * 20;
    return _buildExerciseFigure(
      progress: progress,
      verticalOffset: -pullHeight,
      armAngle: -(1 - (progress * 2 - 1).abs()) * 1.3,
      label: 'Back Exercise',
    );
  }

  Widget _buildShouldersAnimation(double progress) {
    return _buildExerciseFigure(
      progress: progress,
      verticalOffset: 0,
      armAngle: (progress * 2 - 1).abs() * 2.0,
      label: 'Shoulder Exercise',
    );
  }

  Widget _buildArmsAnimation(double progress) {
    final curlAngle = (1 - (progress * 2 - 1).abs()) * 1.8;
    return _buildExerciseFigure(
      progress: progress,
      verticalOffset: 0,
      armAngle: curlAngle,
      label: 'Arm Exercise',
    );
  }

  Widget _buildLegsAnimation(double progress) {
    final squatDepth = (1 - (progress * 2 - 1).abs()) * 30;
    return _buildExerciseFigure(
      progress: progress,
      verticalOffset: squatDepth,
      armAngle: (1 - (progress * 2 - 1).abs()) * 0.8,
      legHeight: 30 - (squatDepth * 0.4),
      label: 'Leg Exercise',
    );
  }

  Widget _buildCoreAnimation(double progress) {
    final crunchAngle = (1 - (progress * 2 - 1).abs()) * 0.3;
    return _buildExerciseFigure(
      progress: progress,
      verticalOffset: 0,
      armAngle: crunchAngle,
      label: 'Core Exercise',
    );
  }

  Widget _buildCardioAnimation(double progress) {
    final runBounce = (progress * 2 - 1).abs() * 10;
    return _buildExerciseFigure(
      progress: progress,
      verticalOffset: -runBounce,
      armAngle: progress * 1.5,
      label: 'Cardio Exercise',
    );
  }

  Widget _buildFullBodyAnimation(double progress) {
    final burpeeDepth = (1 - (progress * 2 - 1).abs()) * 35;
    return _buildExerciseFigure(
      progress: progress,
      verticalOffset: burpeeDepth,
      armAngle: (1 - (progress * 2 - 1).abs()) * 1.5,
      legHeight: 30 - (burpeeDepth * 0.5),
      label: 'Full Body Exercise',
    );
  }

  Widget _buildExerciseFigure({
    required double progress,
    required double verticalOffset,
    required double armAngle,
    double legHeight = 30,
    required String label,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Head
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB74D),
                border: Border.all(
                  color: const Color(0xFF3B82F6),
                  width: 2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Body with movement
            Transform.translate(
              offset: Offset(0, verticalOffset),
              child: Column(
                children: [
                  // Arms and torso
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Left arm
                      Transform.rotate(
                        angle: -armAngle,
                        origin: const Offset(0, 15),
                        child: Column(
                          children: [
                            Container(
                              width: 4,
                              height: 35,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB74D),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Container(
                              width: 16,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF8B5CF6),
                                  progress,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Torso
                      Container(
                        width: 28,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF3B82F6),
                              Color.lerp(
                                const Color(0xFF3B82F6),
                                const Color(0xFF8B5CF6),
                                progress,
                              )!,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Right arm
                      Transform.rotate(
                        angle: armAngle,
                        origin: const Offset(0, 15),
                        child: Column(
                          children: [
                            Container(
                              width: 4,
                              height: 35,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB74D),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Container(
                              width: 16,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF8B5CF6),
                                  progress,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Legs
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: legHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E40AF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 6,
                        height: legHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E40AF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        // Ground line
        Positioned(
          bottom: 0,
          child: Container(
            width: 120,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}
