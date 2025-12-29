import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../localization/app_localizations.dart';

/// Audio recording for case voice notes
class AudioRecorderWidget extends StatefulWidget {
  final String? audioPath;
  final ValueChanged<String?> onRecordingComplete;
  final int maxDurationSeconds;

  const AudioRecorderWidget({
    super.key,
    this.audioPath,
    required this.onRecordingComplete,
    this.maxDurationSeconds = 300, // 5 minutes max
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  String? _recordingPath;
  int _recordingDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.audioPath != null) {
      _recordingPath = widget.audioPath;
      _hasRecording = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.mic_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.voiceNote,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_hasRecording)
                TextButton.icon(
                  onPressed: _deleteRecording,
                  icon: Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                  label: Text(l10n.delete, style: TextStyle(color: colorScheme.error)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Recording controls
          if (!_hasRecording)
            _buildRecordingControls(theme, colorScheme, l10n)
          else
            _buildPlaybackControls(theme, colorScheme, l10n),
        ],
      ),
    );
  }

  Widget _buildRecordingControls(ThemeData theme, ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      children: [
        // Recording indicator
        if (_isRecording) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.error.withAlpha(100),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_recordingDuration),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.recording,
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
        ],

        // Record/Stop button
        Center(
          child: GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isRecording ? 70 : 64,
              height: _isRecording ? 70 : 64,
              decoration: BoxDecoration(
                color: _isRecording ? colorScheme.error : colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? colorScheme.error : colorScheme.primary).withAlpha(60),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isRecording ? l10n.tapToStop : l10n.tapToRecord,
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(ThemeData theme, ColorScheme colorScheme, AppLocalizations l10n) {
    return Row(
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: _isPlaying ? _pausePlayback : _playRecording,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Recording info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.voiceNoteRecorded,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(l10n.ready, style: const TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final path = '${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: path);
        
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });
        
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordingDuration++);
          
          // Auto-stop at max duration
          if (_recordingDuration >= widget.maxDurationSeconds) {
            _stopRecording();
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).microphonePermissionRequired)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      final path = await _recorder.stop();
      
      if (path != null) {
        setState(() {
          _isRecording = false;
          _hasRecording = true;
          _recordingPath = path;
        });
        widget.onRecordingComplete(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;
    try {
      await _player.play(DeviceFileSource(_recordingPath!));
      setState(() => _isPlaying = true);
      
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (e) {
      debugPrint('Error playing recording: $e');
    }
  }

  Future<void> _pausePlayback() async {
    await _player.pause();
    setState(() => _isPlaying = false);
  }

  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
      _recordingDuration = 0;
    });
    widget.onRecordingComplete(null);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
