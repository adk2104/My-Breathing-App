import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'end_meditation_screen.dart';

class MeditationScreen extends StatefulWidget {
  final double inhaleDuration;
  final double holdAfterInhale;
  final double exhaleDuration;
  final double holdAfterExhale;
  final double meditationDuration;

  const MeditationScreen({
    super.key,
    required this.inhaleDuration,
    required this.holdAfterInhale,
    required this.exhaleDuration,
    required this.holdAfterExhale,
    required this.meditationDuration,
  });

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _sessionTimer;
  late AudioPlayer _audioPlayer;
  late AudioPlayer _countingPlayer;
  Timer? _countingTimer;

  // Add constants for asset paths
  static const String _voicePromptsPath = 'breath_phase_voice_prompts';
  static const String _chimesPath = 'chimes';
  static const String _countingPath = 'counting_voice';

  double _speedMultiplier = 1.0;
  double _sessionProgress = 0.0;
  String _currentPhase = 'Inhale';
  String _previousPhase = '';
  int _cycleCount = 0;
  bool _useVoicePrompts = true;
  bool _useChimes = false;
  bool _useCounting = false;
  bool _showAudioSettings = false;
  int _currentCount = 0;
  bool _isAudioPlayingThisSecond = false;
  int? _countdownValue;
  bool _meditationStarted = false;
  bool _isPaused = false;

  double get _adjustedInhaleDuration =>
      widget.inhaleDuration / _speedMultiplier;
  double get _adjustedHoldAfterInhale =>
      widget.holdAfterInhale / _speedMultiplier;
  double get _adjustedExhaleDuration =>
      widget.exhaleDuration / _speedMultiplier;
  double get _adjustedHoldAfterExhale =>
      widget.holdAfterExhale / _speedMultiplier;

  double get _totalCycleDuration =>
      _adjustedInhaleDuration +
      _adjustedHoldAfterInhale +
      _adjustedExhaleDuration +
      _adjustedHoldAfterExhale;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _initializeAnimation();
    _startCountdown();
  }

  void _initializeAudio() {
    _audioPlayer = AudioPlayer();
    _countingPlayer = AudioPlayer();
  }

  Future<void> _playAudio(String assetPath) async {
    _isAudioPlayingThisSecond = true;
    await _audioPlayer.play(AssetSource(assetPath));
    // Reset the flag after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      _isAudioPlayingThisSecond = false;
    });
  }

  Future<void> _playCount(int count) async {
    if (!_isAudioPlayingThisSecond && count <= 10) {
      await _countingPlayer.play(
        AssetSource('$_countingPath/count_$count.wav'),
      );
    }
  }

  void _startCountingForPhase(double duration) {
    _currentCount = 0;
    _countingTimer?.cancel();

    if (!_useCounting) return;

    _countingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _currentCount++;
      if (_currentCount <= duration.floor()) {
        _playCount(_currentCount);
      } else {
        timer.cancel();
      }
    });
  }

  void _handlePhaseChange(String newPhase) {
    if (newPhase != _currentPhase) {
      _previousPhase = _currentPhase;
      _currentPhase = newPhase;
      _handleAudioForPhase(newPhase);
    }
  }

  void _handleAudioForPhase(String phase) {
    final lowerPhase = phase.toLowerCase();
    if (_useVoicePrompts) {
      if (phase == 'Hold') {
        // Use _previousPhase to determine which hold we're in
        final holdType = _previousPhase == 'Exhale'
            ? 'hold_exhale'
            : 'hold_inhale';
        _playAudio('$_voicePromptsPath/$holdType.wav');
      } else {
        _playAudio('$_voicePromptsPath/$lowerPhase.wav');
      }
    } else if (_useChimes) {
      if (phase == 'Hold') {
        // Use _previousPhase to determine which hold we're in
        final holdType = _previousPhase == 'Exhale'
            ? 'chime_hold_exhale'
            : 'chime_hold_inhale';
        _playAudio('$_chimesPath/$holdType.wav');
      } else {
        _playAudio('$_chimesPath/chime_$lowerPhase.wav');
      }
    }

    double phaseDuration;
    switch (phase) {
      case 'Inhale':
        phaseDuration = _adjustedInhaleDuration;
        break;
      case 'Hold':
        if (_previousPhase == 'Exhale') {
          phaseDuration = _adjustedHoldAfterExhale;
        } else {
          phaseDuration = _adjustedHoldAfterInhale;
        }
        break;
      case 'Exhale':
        phaseDuration = _adjustedExhaleDuration;
        break;
      default:
        phaseDuration = 0;
    }

    _startCountingForPhase(phaseDuration);
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_totalCycleDuration * 1000).round()),
    );

    _controller.addListener(() {
      setState(() {
        _updatePhase(_controller.value);
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _cycleCount++;
        _controller.reset();
        _controller.forward();
      }
    });

    // Don't start the animation yet - it will start after countdown
    _controller.reset();
  }

  void _startSessionTimer() {
    final sessionDurationMs = widget.meditationDuration * 60 * 1000;
    const updateInterval = Duration(milliseconds: 100);

    _sessionTimer = Timer.periodic(updateInterval, (timer) {
      if (mounted) {
        setState(() {
          final elapsedTime = timer.tick * updateInterval.inMilliseconds;
          _sessionProgress = elapsedTime / sessionDurationMs;

          if (_sessionProgress >= 1.0) {
            _endSession();
          }
        });
      }
    });
  }

  void _updatePhase(double animationValue) {
    final normalizedTime = animationValue * _totalCycleDuration;
    String newPhase;

    if (normalizedTime < _adjustedInhaleDuration) {
      newPhase = 'Inhale';
    } else if (normalizedTime <
        _adjustedInhaleDuration + _adjustedHoldAfterInhale) {
      newPhase = 'Hold';
    } else if (normalizedTime <
        _adjustedInhaleDuration +
            _adjustedHoldAfterInhale +
            _adjustedExhaleDuration) {
      newPhase = 'Exhale';
    } else {
      newPhase = 'Hold';
    }

    _handlePhaseChange(newPhase);
  }

  void _updateSpeed(double newSpeed) {
    setState(() {
      _speedMultiplier = newSpeed;

      // Store the current position in the animation
      final currentPosition = _controller.value;

      // Update the animation duration
      _controller.duration = Duration(
        milliseconds: (_totalCycleDuration * 1000).round(),
      );

      // If the animation was running, restart it from the current position
      if (_controller.isAnimating) {
        _controller.value = currentPosition;
        _controller.forward();
      }
    });
  }

  void _endSession() {
    _sessionTimer.cancel();
    _controller.stop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => EndMeditationScreen(
          inhaleDuration: widget.inhaleDuration,
          holdAfterInhale: widget.holdAfterInhale,
          exhaleDuration: widget.exhaleDuration,
          holdAfterExhale: widget.holdAfterExhale,
          meditationDuration: widget.meditationDuration,
        ),
      ),
    );
  }

  void _startCountdown() {
    setState(() {
      _countdownValue = 3;
      // Reset the controller and phase at the start of countdown
      _controller.reset();
      _currentPhase = 'Inhale';
      _previousPhase = '';
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue == 1) {
        timer.cancel();
        setState(() {
          _countdownValue = null;
          _meditationStarted = true;
        });
        _startMeditation();
      } else {
        setState(() {
          _countdownValue = _countdownValue! - 1;
        });
      }
    });
  }

  void _startMeditation() {
    // Ensure we start from the beginning
    _controller.reset();
    _currentPhase = 'Inhale';
    _previousPhase = '';

    // Play the initial inhale prompt
    _handleAudioForPhase('Inhale');

    // Start the animation and timer
    _controller.forward();
    _startSessionTimer();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _controller.stop();
        _sessionTimer.cancel();
        _countingTimer?.cancel();
      } else {
        _controller.forward();
        _startSessionTimer();
      }
    });
  }

  void _updateSessionProgress(double value) {
    if (!mounted) return;

    setState(() {
      _sessionProgress = value;
    });

    // Cancel existing timer
    if (_sessionTimer.isActive) {
      _sessionTimer.cancel();
    }

    // Calculate the new elapsed time in milliseconds
    final sessionDurationMs = widget.meditationDuration * 60 * 1000;
    final elapsedMs = (value * sessionDurationMs).round();
    const updateInterval = Duration(milliseconds: 100);

    // Start a new timer that continues from the new position
    _sessionTimer = Timer.periodic(updateInterval, (timer) {
      if (mounted) {
        setState(() {
          final currentElapsedMs =
              elapsedMs + (timer.tick * updateInterval.inMilliseconds);
          _sessionProgress = currentElapsedMs / sessionDurationMs;

          if (_sessionProgress >= 1.0) {
            _endSession();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _countingPlayer.dispose();
    _countingTimer?.cancel();
    _controller.dispose();
    _sessionTimer.cancel();
    super.dispose();
  }

  String _formatDuration(double minutes) {
    final totalSeconds = (minutes * 60).round();
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Widget _buildAudioSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audio Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'Voice Prompts',
              style: TextStyle(color: Colors.white),
            ),
            value: _useVoicePrompts,
            onChanged: (value) {
              setState(() {
                _useVoicePrompts = value;
                if (value) {
                  _useChimes = false;
                }
              });
            },
          ),
          SwitchListTile(
            title: const Text('Chimes', style: TextStyle(color: Colors.white)),
            value: _useChimes,
            onChanged: (value) {
              setState(() {
                _useChimes = value;
                if (value) {
                  _useVoicePrompts = false;
                }
              });
            },
          ),
          SwitchListTile(
            title: const Text(
              'Voice Count',
              style: TextStyle(color: Colors.white),
            ),
            value: _useCounting,
            onChanged: (value) {
              setState(() {
                _useCounting = value;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final squareSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leadingWidth: 140,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: TextButton.icon(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            label: const Text(
              'Back',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text('Breathing Session'),
        actions: [
          if (_meditationStarted) ...[
            IconButton(
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
              ),
              onPressed: _togglePause,
            ),
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.white),
              onPressed: _endSession,
            ),
          ],
          IconButton(
            icon: Icon(
              _showAudioSettings ? Icons.volume_up : Icons.volume_up_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showAudioSettings = !_showAudioSettings;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_showAudioSettings) _buildAudioSettings(),
                if (_showAudioSettings) const SizedBox(height: 20),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: squareSize,
                        height: squareSize,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                      ),
                      if (_meditationStarted) ...[
                        Text(
                          _currentPhase,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return CustomPaint(
                              size: Size(squareSize, squareSize),
                              painter: BreathingBallPainter(
                                progress: _controller.value,
                                inhaleDuration: _adjustedInhaleDuration,
                                holdAfterInhale: _adjustedHoldAfterInhale,
                                exhaleDuration: _adjustedExhaleDuration,
                                holdAfterExhale: _adjustedHoldAfterExhale,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                if (_meditationStarted) ...[
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Speed: ',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              '${(_speedMultiplier * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        Slider(
                          value: _speedMultiplier,
                          min: 0.5,
                          max: 1.5,
                          divisions: 20,
                          onChanged: _updateSpeed,
                        ),
                        const SizedBox(height: 20),
                        Slider(
                          value: _sessionProgress,
                          onChanged: _updateSessionProgress,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatDuration(_sessionProgress * widget.meditationDuration)} / ${_formatDuration(widget.meditationDuration)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_countdownValue != null)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Text(
                  _countdownValue.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BreathingBallPainter extends CustomPainter {
  final double progress;
  final double inhaleDuration;
  final double holdAfterInhale;
  final double exhaleDuration;
  final double holdAfterExhale;

  BreathingBallPainter({
    required this.progress,
    required this.inhaleDuration,
    required this.holdAfterInhale,
    required this.exhaleDuration,
    required this.holdAfterExhale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final totalDuration =
        inhaleDuration + holdAfterInhale + exhaleDuration + holdAfterExhale;
    final normalizedTime = progress * totalDuration;

    double x, y;
    if (normalizedTime < inhaleDuration) {
      // Inhale - move up left side
      final t = normalizedTime / inhaleDuration;
      x = 0;
      y = size.height * (1 - t);
    } else if (normalizedTime < inhaleDuration + holdAfterInhale) {
      // Hold at top - move from left to right
      final t = (normalizedTime - inhaleDuration) / holdAfterInhale;
      x = size.width * t;
      y = 0;
    } else if (normalizedTime <
        inhaleDuration + holdAfterInhale + exhaleDuration) {
      // Exhale - move down right side
      final t =
          (normalizedTime - inhaleDuration - holdAfterInhale) / exhaleDuration;
      x = size.width;
      y = size.height * t;
    } else {
      // Hold at bottom - move from right to left
      final t =
          (normalizedTime - inhaleDuration - holdAfterInhale - exhaleDuration) /
          holdAfterExhale;
      x = size.width * (1 - t);
      y = size.height;
    }

    canvas.drawCircle(Offset(x, y), 10, paint);
  }

  @override
  bool shouldRepaint(BreathingBallPainter oldDelegate) => true;
}
