import 'package:flutter/material.dart';
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
      _player.onPlayerComplete.listen((_) => setState(() { _isPlaying = false; _position = Duration.zero; }));
      
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
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.audiotrack, size: 48, color: theme.colorScheme.secondary),
             const SizedBox(height: 16),
             Text(
               widget.fileName,
               style: theme.textTheme.titleMedium,
               textAlign: TextAlign.center,
               maxLines: 2,
             ),
             const SizedBox(height: 24),
             if (_isLoading)
               const CircularProgressIndicator()
             else ...[
               Slider(
                 value: _position.inSeconds.toDouble(),
                 max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1,
                 onChanged: (v) async {
                   final pos = Duration(seconds: v.toInt());
                   await _player.seek(pos);
                 },
               ),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(_formatDuration(_position), style: theme.textTheme.bodySmall),
                   Text(_formatDuration(_duration), style: theme.textTheme.bodySmall),
                 ],
               ),
               const SizedBox(height: 16),
               IconButton.filled(
                 onPressed: _togglePlay,
                 icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                 iconSize: 32,
                 style: IconButton.styleFrom(
                   backgroundColor: theme.colorScheme.secondary,
                   foregroundColor: Colors.white,
                 ),
               ),
             ],
             const SizedBox(height: 16),
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: const Text('Close'),
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

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isLoading)
            const CircularProgressIndicator(color: Colors.white)
          else if (_error != null)
             Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(Icons.error_outline, color: Colors.red, size: 48),
                 const SizedBox(height: 16),
                 Text('Video Error: $_error', style: const TextStyle(color: Colors.white)),
               ],
             )
          else
            AspectRatio(
              aspectRatio: _videoPlayerController.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),
            
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
