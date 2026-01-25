import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class AudioPlayerDialog extends StatefulWidget {
  final String url;
  final String fileName;

  const AudioPlayerDialog({super.key, required this.url, required this.fileName});

  @override
  State<AudioPlayerDialog> createState() => _AudioPlayerDialogState();
}

class _AudioPlayerDialogState extends State<AudioPlayerDialog> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }
  
  Future<void> _initPlayer() async {
    try {
      await _player.setSourceUrl(widget.url);
      _duration = await _player.getDuration() ?? Duration.zero;
      
      _player.onDurationChanged.listen((d) => setState(() => _duration = d));
      _player.onPositionChanged.listen((p) => setState(() => _position = p));
      _player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() { 
            _isPlaying = false; 
            _position = Duration.zero; 
          });
        }
      });
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Audio init error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      final state = _player.state;
      if (state == PlayerState.playing) {
        await _player.pause();
        setState(() => _isPlaying = false);
      } else {
        // If completed, re-play from source (safest for Linux)
        if (state == PlayerState.completed || _position >= _duration) {
           await _player.stop();
           await _player.play(UrlSource(widget.url));
        } else {
           // Provide fallback for normal resume
           await _player.resume();
        }
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      debugPrint('Toggle play error: $e');
      // If resume failed, try force play
      try {
        await _player.play(UrlSource(widget.url));
        setState(() => _isPlaying = true);
      } catch (e2) {
         debugPrint('Force play error: $e2');
      }
    }
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500, // Increased width further
          minWidth: screenWidth < 500 ? screenWidth * 0.95 : 400,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 48, 32, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Visualizer / Icon
                   Container(
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(
                       color: primaryColor.withAlpha(20),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(Icons.music_note_rounded, size: 40, color: primaryColor),
                   ),
                   const SizedBox(height: 20),
                   
                   // Metadata
                   Text(
                     widget.fileName,
                     style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                     textAlign: TextAlign.center,
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                   const SizedBox(height: 24),
                   
                   if (_isLoading)
                     const Padding(
                       padding: EdgeInsets.all(16.0),
                       child: SizedBox(
                         width: 24, height: 24, 
                         child: CircularProgressIndicator(strokeWidth: 2),
                       ),
                     )
                   else ...[
                     // Progress Bar
                     SizedBox(
                       height: 20,
                       child: SliderTheme(
                         data: SliderTheme.of(context).copyWith(
                           thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                           overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                           trackHeight: 4,
                           activeTrackColor: primaryColor,
                           inactiveTrackColor: primaryColor.withAlpha(50),
                           thumbColor: primaryColor,
                         ),
                         child: Slider(
                           value: _position.inSeconds.toDouble(),
                           max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1,
                           onChanged: (v) async {
                             final pos = Duration(seconds: v.toInt());
                             await _player.seek(pos);
                           },
                         ),
                       ),
                     ),
                     
                     // Time Labels
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(_formatDuration(_position), style: TextStyle(fontSize: 10, color: Colors.grey[600], fontFeatures: [const FontFeature.tabularFigures()])),
                           Text(_formatDuration(_duration), style: TextStyle(fontSize: 10, color: Colors.grey[600], fontFeatures: [const FontFeature.tabularFigures()])),
                         ],
                       ),
                     ),
                     
                     const SizedBox(height: 16),
                     
                     // Controls
                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         IconButton(
                           onPressed: () {
                             final newPos = _position - const Duration(seconds: 10);
                             _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                           },
                           icon: Icon(Icons.replay_10_rounded, color: Colors.grey[600], size: 28),
                         ),
                         const SizedBox(width: 16),
                         Container(
                           decoration: BoxDecoration(
                             color: primaryColor,
                             shape: BoxShape.circle,
                             boxShadow: [
                               BoxShadow(
                                 color: primaryColor.withAlpha(100),
                                 blurRadius: 12,
                                 offset: const Offset(0, 4),
                               ),
                             ],
                           ),
                           child: IconButton(
                             onPressed: _togglePlay,
                             icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                             iconSize: 32,
                             color: Colors.white,
                             padding: const EdgeInsets.all(12),
                             constraints: const BoxConstraints(),
                             style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                           ),
                         ),
                         const SizedBox(width: 16),
                         IconButton(
                           onPressed: () {
                              final newPos = _position + const Duration(seconds: 10);
                              _player.seek(newPos > _duration ? _duration : newPos);
                           },
                           icon: Icon(Icons.forward_10_rounded, color: Colors.grey[600], size: 28),
                         ),
                       ],
                     ),
                   ],
                ],
              ),
            ),
            
            // Close Button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: Colors.grey[500],
                splashRadius: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryImageViewerDialog extends StatefulWidget {
  final List<String> urls;
  final List<String> fileNames;
  final int initialIndex;

  const GalleryImageViewerDialog({
    super.key,
    required this.urls,
    required this.fileNames,
    this.initialIndex = 0,
  }) : assert(urls.length == fileNames.length);

  @override
  State<GalleryImageViewerDialog> createState() => _GalleryImageViewerDialogState();
}

class _GalleryImageViewerDialogState extends State<GalleryImageViewerDialog> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < widget.urls.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width * 0.8;
    final dialogHeight = size.height * 0.8;

    final onSurface = theme.colorScheme.onSurface;
    final scrim = theme.colorScheme.scrim.withAlpha(150);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(12),
          // No box shadow on the container itself to avoid "box" look
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Image PageView
            PageView.builder(
              controller: _pageController,
              itemCount: widget.urls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    widget.urls[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, prog) => prog == null 
                        ? child 
                        : Center(child: CircularProgressIndicator(color: onSurface)),
                    errorBuilder: (_, __, ___) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: onSurface, size: 48),
                        const SizedBox(height: 8),
                         Text('Failed to load image', style: TextStyle(color: onSurface))
                      ],
                    ),
                  ),
                );
              },
            ),

            // Top Bar: Counter and FileName
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [scrim, Colors.transparent],
                  ),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentIndex + 1} / ${widget.urls.length}',
                      style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        widget.fileNames[_currentIndex],
                        style: TextStyle(color: onSurface),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                        icon: Icon(Icons.close, color: onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
              ),
            ),

            // Navigation Buttons
            if (widget.urls.length > 1) ...[
              if (_currentIndex > 0)
                Positioned(
                  left: 10,
                  child: IconButton.filled(
                    onPressed: _previous,
                    icon: const Icon(Icons.chevron_left, size: 32),
                    style: IconButton.styleFrom(
                      backgroundColor: scrim,
                      foregroundColor: onSurface,
                    ),
                  ),
                ),
              if (_currentIndex < widget.urls.length - 1)
                Positioned(
                  right: 10,
                  child: IconButton.filled(
                    onPressed: _next,
                    icon: const Icon(Icons.chevron_right, size: 32),
                    style: IconButton.styleFrom(
                      backgroundColor: scrim,
                      foregroundColor: onSurface,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class VideoPlayerDialog extends StatefulWidget {
  final String url;
  final String fileName;

  const VideoPlayerDialog({super.key, required this.url, required this.fileName});

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoPlayerController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        placeholder: const Center(child: CircularProgressIndicator()),
        showOptions: true,
        optionsBuilder: (context, defaultOptions) async {
          _showSpeedMenu(context);
        },
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _showSpeedMenu(BuildContext context) {
    setState(() => _showSettings = !_showSettings);
  }

  Widget _buildSpeedMenu() {
    final List<double> speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentSpeed = _videoPlayerController.value.playbackSpeed;

    return Positioned(
      right: 32, // More aggressive positioning for Linux desktop
      bottom: 40, 
      child: Material(
        elevation: 12,
        color: Theme.of(this.context).colorScheme.surface.withAlpha(250),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 110, // Slimmer for professional look
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(this.context).dividerColor.withAlpha(60)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Speed',
                  style: Theme.of(this.context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(this.context).colorScheme.primary,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...speeds.map((speed) {
                final isSelected = currentSpeed == speed;
                return InkWell(
                  onTap: () {
                    _videoPlayerController.setPlaybackSpeed(speed);
                    setState(() => _showSettings = false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: isSelected ? Theme.of(this.context).colorScheme.primary : Colors.transparent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${speed}x',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Theme.of(this.context).colorScheme.primary : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const Divider(height: 1),
              InkWell(
                onTap: () => setState(() => _showSettings = false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(this.context).colorScheme.error,
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

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Dialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       elevation: 8,
       backgroundColor: theme.colorScheme.surface,
       insetPadding: const EdgeInsets.all(16),
       child: Container(
         constraints: BoxConstraints(
           maxWidth: 800, // Constrain width like Audio Player
           maxHeight: MediaQuery.of(context).size.height * 0.85,
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             // Header
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Row(
                   children: [
                     Icon(Icons.play_circle_fill_rounded, color: theme.colorScheme.primary, size: 24),
                     const SizedBox(width: 12),
                     ConstrainedBox(
                       constraints: BoxConstraints(maxWidth: screenWidth * 0.5),
                       child: Text(
                         widget.fileName,
                         style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                   ],
                 ),
                 IconButton(
                   icon: Icon(Icons.close, color: onSurface.withAlpha(150)),
                   onPressed: () => Navigator.pop(context),
                   splashRadius: 20,
                 ),
               ],
             ),
             ),
             
             const Divider(height: 1),
             
             // Video Content
             Flexible(
               child: Container(
                 color: Colors.black, // Player background remains black for video contrast includes rounded corners via ClipRRect if desired, but square is standard for video area
                 child: _isLoading
                     ? const SizedBox(
                         height: 300, 
                         child: Center(child: CircularProgressIndicator(color: Colors.white)),
                       )
                     : _error != null
                         ? SizedBox(
                             height: 300,
                             child: Center(
                               child: Column(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                   const SizedBox(height: 16),
                                   Text('Video Error: $_error', style: const TextStyle(color: Colors.white)),
                                 ],
                               ),
                             ),
                           )
                         : AspectRatio(
                             aspectRatio: _videoPlayerController.value.aspectRatio,
                             child: Stack(
                               children: [
                                 GestureDetector(
                                   onTap: () {
                                     if (_showSettings) setState(() => _showSettings = false);
                                   },
                                   child: Chewie(controller: _chewieController!),
                                 ),
                                 if (_showSettings) _buildSpeedMenu(),
                               ],
                             ),
                           ),
               ),
             ),
           ],
         ),
       ),
    );
  }
}
