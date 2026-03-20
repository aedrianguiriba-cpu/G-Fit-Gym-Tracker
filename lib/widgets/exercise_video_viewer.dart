import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';

class ExerciseVideoViewer extends StatefulWidget {
  final String? videoUrl;
  final String exerciseName;
  final String? instructions;

  const ExerciseVideoViewer({
    Key? key,
    this.videoUrl,
    required this.exerciseName,
    this.instructions,
  }) : super(key: key);

  @override
  State<ExerciseVideoViewer> createState() => _ExerciseVideoViewerState();
}

class _ExerciseVideoViewerState extends State<ExerciseVideoViewer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _initializeVideoPlayer();
    } else {
      _hasError = true;
    }
  }

  void _initializeVideoPlayer() {
    try {
      final Uri videoUri = _parseVideoUrl(widget.videoUrl!);
      _videoPlayerController = VideoPlayerController.networkUrl(videoUri);

      _videoPlayerController.initialize().then((_) {
        if (mounted) {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            autoPlay: false,
            looping: false,
            progressIndicatorDelay: const Duration(milliseconds: 200),
            materialProgressColors: ChewieProgressColors(
              playedColor: Colors.blue,
              handleColor: Colors.blue.shade800,
              backgroundColor: Colors.grey[800]!,
              bufferedColor: Colors.grey[700] ?? Colors.grey,
            ),
          );
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((error) {
        print('Error initializing video: $error');
        setState(() {
          _hasError = true;
        });
      });
    } catch (e) {
      print('Error parsing video URL: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  Uri _parseVideoUrl(String url) {
    // Handle YouTube URLs
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      String videoId = '';
      
      if (url.contains('watch?v=')) {
        videoId = url.split('watch?v=').last.split('&').first;
      } else if (url.contains('youtu.be/')) {
        videoId = url.split('youtu.be/').last.split('?').first;
      }

      // Convert to embed URL for better compatibility
      if (videoId.isNotEmpty) {
        return Uri.parse('https://www.youtube.com/embed/$videoId');
      }
    }

    // Return as-is if it's a direct video URL
    return Uri.parse(url);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _openInBrowser() async {
    if (widget.videoUrl != null) {
      final Uri url = Uri.parse(widget.videoUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Player or Placeholder
          if (_isInitialized && _chewieController != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Chewie(controller: _chewieController!),
              ),
            )
          else if (_hasError)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined,
                      size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    'Video not available',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ElevatedButton.icon(
                        onPressed: _openInBrowser,
                        icon: const Icon(Icons.open_in_browser, size: 18),
                        label: const Text('Watch on Browser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Exercise Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise Name
                Text(
                  widget.exerciseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                // Instructions
                if (widget.instructions != null &&
                    widget.instructions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Instructions:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.instructions!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[300],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Open in Browser Button
                if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openInBrowser,
                        icon: const Icon(Icons.open_in_browser, size: 18),
                        label: const Text('Open Video in Browser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
