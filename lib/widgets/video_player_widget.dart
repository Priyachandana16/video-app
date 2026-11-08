import 'dart:async';
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
  final BoxFit fit;

  const VideoPlayerWidget({
    super.key,
    required this.videoSource,
    this.isAsset = false,
    this.autoPlay = true,
    this.looping = true,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.contain,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isMuted = kIsWeb; // Muted by default on web to satisfy browser autoplay policy
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_isInitialized) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _controller?.pause();
    }
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
    _controlsTimer?.cancel();
    _controller?.pause();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _scheduleControlsAutoHide() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _initController() {
    _controlsTimer?.cancel();
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = '';
    });

    final rawSrc = widget.videoSource.trim();
    String cleanSrc = rawSrc;
    if (cleanSrc.startsWith('/assets/')) {
      cleanSrc = cleanSrc.substring(1);
    }

    VideoPlayerController controller;

    if (cleanSrc.startsWith('http://') || cleanSrc.startsWith('https://')) {
      controller = VideoPlayerController.networkUrl(Uri.parse(cleanSrc));
    } else if (cleanSrc.startsWith('/exports/')) {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(kIsWeb ? cleanSrc : 'http://localhost:5000$cleanSrc'),
      );
    } else if (cleanSrc.startsWith('assets/') || widget.isAsset) {
      if (kIsWeb) {
        final webPath = cleanSrc.startsWith('/') ? cleanSrc : '/$cleanSrc';
        controller = VideoPlayerController.networkUrl(Uri.parse(webPath));
      } else {
        controller = VideoPlayerController.asset(cleanSrc);
      }
    } else if (!kIsWeb && File(cleanSrc).existsSync()) {
      controller = VideoPlayerController.file(File(cleanSrc));
    } else {
      final fallbackAsset = widget.aspectRatio < 1
          ? 'assets/templates/template_03_sample_result.mp4'
          : 'assets/templates/template_01_sample_result.mp4';
      controller = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse('/$fallbackAsset'))
          : VideoPlayerController.asset(fallbackAsset);
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
        _scheduleControlsAutoHide();
      }
      controller.addListener(_onControllerUpdate);
    }).catchError((err) {
      debugPrint('Error initializing video player for $cleanSrc: $err');
      if (!mounted) return;

      // Fallback attempt with known asset
      final fallbackAsset = widget.aspectRatio < 1
          ? 'assets/templates/template_03_sample_result.mp4'
          : 'assets/templates/template_01_sample_result.mp4';

      if (cleanSrc != fallbackAsset) {
        final fallbackController = kIsWeb
            ? VideoPlayerController.networkUrl(Uri.parse('/$fallbackAsset'))
            : VideoPlayerController.asset(fallbackAsset);

        _controller = fallbackController;
        fallbackController.initialize().then((_) {
          if (!mounted) return;
          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
          fallbackController.setLooping(widget.looping);
          fallbackController.setVolume(_isMuted ? 0.0 : 1.0);
          if (widget.autoPlay) {
            fallbackController.play();
            _scheduleControlsAutoHide();
          }
          fallbackController.addListener(_onControllerUpdate);
        }).catchError((e2) {
          debugPrint('Secondary fallback failed: $e2');
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
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null || !_isInitialized) return;

    if (c.value.isPlaying) {
      c.pause();
      _controlsTimer?.cancel();
      setState(() {
        _showControls = true;
      });
    } else {
      if (c.value.position >= c.value.duration) {
        c.seekTo(Duration.zero);
      }
      c.play();
      _scheduleControlsAutoHide();
      setState(() {});
    }
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
          if (_showControls && (_controller?.value.isPlaying ?? false)) {
            _scheduleControlsAutoHide();
          }
        },
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Video Layer - 100% Exact Containment, Never Cropped, Text & Borders Visible
              if (_isInitialized && c != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : widget.aspectRatio,
                    child: VideoPlayer(c),
                  ),
                )
              else if (_hasError)
                Container(
                  color: AppColors.surfaceDark,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.royalCrimson, size: 36),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: AppColors.surfaceDark,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _initController,
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: Text(
                          'Retry',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold),
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
                      strokeWidth: 2.2,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ),

              // 2. Playback Controls - Placed Carefully to Never Obscure Invitation Face or Text
              if (_isInitialized && c != null)
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top bar: HD Quality Badge + Mute Toggle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.goldBorder, width: 0.8),
                                  ),
                                  child: Text(
                                    'HD 1080p',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.champagne,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _toggleMute,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.goldBorder, width: 0.8),
                                    ),
                                    child: Icon(
                                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                      color: AppColors.primaryGold,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Subtle center icon shown ONLY when paused (never blocks during playback)
                          if (!c.value.isPlaying)
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.65),
                                  border: Border.all(color: AppColors.primaryGold, width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: AppColors.primaryGold,
                                  size: 26,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          // Bottom Bar: Integrated Play/Pause + Scrubber + Timestamps (Non-Obtrusive)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VideoProgressIndicator(
                                  c,
                                  allowScrubbing: true,
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  colors: const VideoProgressColors(
                                    playedColor: AppColors.primaryGold,
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.white12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: _togglePlayPause,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          c.value.isPlaying
                                              ? Icons.pause_rounded
                                              : (c.value.position >= c.value.duration && c.value.duration > Duration.zero)
                                                  ? Icons.replay_rounded
                                                  : Icons.play_arrow_rounded,
                                          color: AppColors.primaryGold,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDuration(c.value.position),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDuration(c.value.duration),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
