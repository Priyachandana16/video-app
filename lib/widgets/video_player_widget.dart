import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/app_colors.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoSource;
  final bool isAsset;
  final bool autoPlay;
  final bool looping;
  final double aspectRatio;

  const VideoPlayerWidget({
    super.key,
    required this.videoSource,
    this.isAsset = false,
    this.autoPlay = true,
    this.looping = true,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isMuted = kIsWeb; // Muted by default on web to satisfy browser autoplay policy

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoSource != widget.videoSource) {
      _disposeController();
      _initController();
    }
  }

  void _disposeController() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _initController() {
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = '';
    });

    VideoPlayerController controller;

    final src = widget.videoSource;
    if (src.startsWith('http://') || src.startsWith('https://')) {
      controller = VideoPlayerController.networkUrl(Uri.parse(src));
    } else if (src.startsWith('/exports/') || src.startsWith('/assets/')) {
      controller = VideoPlayerController.networkUrl(Uri.parse(kIsWeb ? src : 'http://localhost:5000$src'));
    } else if (widget.isAsset || src.startsWith('assets/')) {
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse('/$src'));
      } else {
        controller = VideoPlayerController.asset(src);
      }
    } else if (!kIsWeb) {
      controller = VideoPlayerController.file(File(src));
    } else {
      controller = VideoPlayerController.networkUrl(Uri.parse('/assets/templates/template_01_sample_result.mp4'));
    }

    _controller = controller;

    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
      controller.setLooping(widget.looping);
      controller.setVolume(_isMuted ? 0.0 : 1.0);
      if (widget.autoPlay) {
        controller.play();
      }
      controller.addListener(_onControllerUpdate);
    }).catchError((err) {
      debugPrint('Error initializing video player: $err');
      if (!mounted) return;

      // Web/Network fallback: if local asset failed in web, try local server route
      if (kIsWeb && widget.videoSource.startsWith('assets/')) {
        final fallbackUrl = 'http://localhost:5000/${widget.videoSource}';
        final fallbackController = VideoPlayerController.networkUrl(Uri.parse(fallbackUrl));
        _controller = fallbackController;
        fallbackController.initialize().then((_) {
          if (!mounted) return;
          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
          fallbackController.setLooping(widget.looping);
          fallbackController.setVolume(_isMuted ? 0.0 : 1.0);
          if (widget.autoPlay) fallbackController.play();
          fallbackController.addListener(_onControllerUpdate);
        }).catchError((e2) {
          debugPrint('Fallback video player error: $e2');
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Video could not be played. Tap to retry.';
            });
          }
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video. Tap to retry.';
        });
      }
    });
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null || !_isInitialized) return;

    if (c.value.isPlaying) {
      c.pause();
    } else {
      if (c.value.position >= c.value.duration) {
        c.seekTo(Duration.zero);
      }
      c.play();
    }
    setState(() {});
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      _isMuted = !_isMuted;
      c.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video Layer
              if (_isInitialized && c != null)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: c.value.size.width > 0 ? c.value.size.width : 720,
                      height: c.value.size.height > 0 ? c.value.size.height : 1280,
                      child: VideoPlayer(c),
                    ),
                  ),
                )
              else if (_hasError)
                Container(
                  color: AppColors.surfaceDark,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.royalCrimson, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: AppColors.surfaceDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _initController,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(
                          'Retry',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ),

              // Controls Overlay
              if (_isInitialized && c != null && _showControls)
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top bar (Quality Pill + Mute Button)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.goldBorder, width: 0.8),
                                ),
                                child: Text(
                                  'HD 1080p',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.champagne,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _toggleMute,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.goldBorder, width: 0.8),
                                  ),
                                  child: Icon(
                                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                    color: AppColors.primaryGold,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Center Play/Pause/Replay button
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceDark.withValues(alpha: 0.85),
                              border: Border.all(color: AppColors.primaryGold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGold.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Icon(
                              c.value.isPlaying
                                  ? Icons.pause_rounded
                                  : (c.value.position >= c.value.duration && c.value.duration > Duration.zero)
                                      ? Icons.replay_rounded
                                      : Icons.play_arrow_rounded,
                              color: AppColors.primaryGold,
                              size: 32,
                            ),
                          ),
                        ),

                        // Bottom scrubber and duration
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Column(
                            children: [
                              VideoProgressIndicator(
                                c,
                                allowScrubbing: true,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                colors: const VideoProgressColors(
                                  playedColor: AppColors.primaryGold,
                                  bufferedColor: Colors.white24,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(c.value.position),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(c.value.duration),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
