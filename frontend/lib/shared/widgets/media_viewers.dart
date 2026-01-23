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

class ImageViewerDialog extends StatelessWidget {
  final String url;
  final String fileName;

  const ImageViewerDialog({super.key, required this.url, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              url,
              loadingBuilder: (_, child, prog) => prog == null ? child : const CircularProgressIndicator(color: Colors.white),
              errorBuilder: (_, __, ___) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.broken_image, color: Colors.white, size: 48), Text('Failed to load image', style: TextStyle(color: Colors.white))],
              ),
            ),
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
