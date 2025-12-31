import 'dart:async';

import 'dart:io';
import 'package:flutter/foundation.dart';
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15), // alpha 40/255 approx 0.15
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer if recording
          if (_isRecording) ...[
            Text(
              _formatDuration(_recordingDuration),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.recording, style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
          ],

          // Big Record Button
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isRecording ? 80 : 72,
              height: _isRecording ? 80 : 72,
              decoration: BoxDecoration(
                color: _isRecording ? colorScheme.error : const Color(0xFF00C853), // Green for record
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? colorScheme.error : const Color(0xFF00C853)).withValues(alpha: 0.4),
                    blurRadius: _isRecording ? 20 : 10,
                    spreadRadius: _isRecording ? 4 : 0,
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
          const SizedBox(height: 16),
          Text(
            _isRecording ? l10n.tapToStop : l10n.tapToRecord,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
            color: Colors.green.withValues(alpha: 0.1),
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

  // Linux-specific recording process
  Process? _linuxRecordingProcess;

  Future<void> _startRecording() async {
    try {
      // Check permissions (handled by OS/plugin usually, but good to wrap)
      // Plugin permission check might fail or be irrelevant for native process on Linux, 
      // but we keep it for consistency on other platforms.
      bool hasPermission = true;
      if (!kIsWeb && (Platform.isMacOS || Platform.isAndroid || Platform.isIOS)) {
        hasPermission = await _recorder.hasPermission();
      }

      if (hasPermission) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        // Setup path
        String path = '';
        if (kIsWeb) {
           // Plugin handles web path (blob)
           path = ''; 
        } else {
           // For local files
           final dir = Directory.systemTemp.createTempSync();
           path = '${dir.path}/audio_$timestamp.${Platform.isLinux ? "wav" : "m4a"}';
        }

        if (!kIsWeb && Platform.isLinux) {
           // Use native 'arecord' on Linux as fallback/primary
           // -f cd (16 bit little endian, 44100Hz, stereo)
           // -t wav (file type)
           // -d maxDuration (optional, but we manage manually)
           await _startLinuxRecording(path);
        } else {
           // Use plugin for others
           await _recorder.start(const RecordConfig(), path: path);
        }
        
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
          _recordingPath = path; // Store path immediately for Linux
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
      if (mounted) {
        String errorMessage = AppLocalizations.of(context).recordingError;
        if (!kIsWeb && Platform.isLinux && e.toString().contains('ProcessException')) {
           // Even our fallback failed?
           errorMessage = 'Linux recording requires "arecord" (ALSA) or "parecord".';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
      _resetState();
    }
  }

  Future<void> _startLinuxRecording(String path) async {
     // Ensure directory exists
     final file = File(path);
     if (!file.parent.existsSync()) file.parent.createSync(recursive: true);

     // Check for arecord availability (simple heuristic: try running it)
     // Actually, we'll just try spawning.
     _linuxRecordingProcess = await Process.start('arecord', [
       '-f', 'cd', // Quality: CD (16 bit, 44.1kHz)
       '-t', 'wav',
       path
     ]);
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      
      String? path = _recordingPath;

      if (!kIsWeb && Platform.isLinux) {
         // Stop Linux process
         _linuxRecordingProcess?.kill(ProcessSignal.sigterm); // Try nice kill
         _linuxRecordingProcess = null;
         // Wait a tiny bit for file verify?
         await Future.delayed(const Duration(milliseconds: 200));
      } else {
         // Stop plugin
         path = await _recorder.stop();
      }
      
      if (path != null) {
        setState(() {
          _isRecording = false;
          _hasRecording = true;
          _recordingPath = path;
        });
        widget.onRecordingComplete(path);
      } else {
        _resetState();
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _resetState();
    }
  }

  void _resetState() {
     setState(() {
      _isRecording = false;
      _recordingDuration = 0;
    });
    _timer?.cancel();
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
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
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
      _isRecording = false; 
    });
    widget.onRecordingComplete(null);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
