import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

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
  // Define theme colors
  static const deepNavy = Color(0xFF0D1B2A);
  static const mistyGray = Color(0xFFCAD2C5);
  static const activeBlue = Color(0xFF3A86FF);
  static const inactiveBlue = Color(0xFF415A77);
  static const overlayBlue = Color(0x553A86FF);
  static const buttonBg = Color(0xFF1B263B);
  static const buttonText = Color(0xFFE0FBFC);

  // ... existing variables and methods ...

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final squareSize = size.width * 0.7;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: deepNavy,
        appBarTheme: const AppBarTheme(
          backgroundColor: deepNavy,
          foregroundColor: mistyGray,
          elevation: 0,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: activeBlue,
          inactiveTrackColor: inactiveBlue,
          thumbColor: activeBlue,
          overlayColor: overlayBlue,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: mistyGray),
          bodyMedium: TextStyle(color: mistyGray),
          titleMedium: TextStyle(color: mistyGray),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 140,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_back, color: mistyGray),
              label: const Text(
                'Start Screen',
                style: TextStyle(color: mistyGray, fontSize: 16),
              ),
              style: TextButton.styleFrom(
                backgroundColor: buttonBg,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          title: const Text('Breathing Session'),
          actions: [
            IconButton(
              icon: Icon(
                _showAudioSettings ? Icons.volume_up : Icons.volume_up_outlined,
                color: mistyGray,
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
                            border: Border.all(color: inactiveBlue, width: 2),
                          ),
                        ),
                        if (_meditationStarted) ...[
                          Text(
                            _currentPhase,
                            style: const TextStyle(
                              color: mistyGray,
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
                                  ballColor: activeBlue,
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
                                style: TextStyle(color: mistyGray),
                              ),
                              Text(
                                '${(_speedMultiplier * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(color: mistyGray),
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
                          LinearProgressIndicator(
                            value: _sessionProgress,
                            backgroundColor: inactiveBlue,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              activeBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_formatDuration(_sessionProgress * widget.meditationDuration)} / ${_formatDuration(widget.meditationDuration)}',
                            style: const TextStyle(color: mistyGray),
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
                color: deepNavy.withOpacity(0.8),
                child: Center(
                  child: Text(
                    _countdownValue.toString(),
                    style: TextStyle(
                      color: activeBlue,
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: buttonBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audio Settings',
            style: TextStyle(
              color: mistyGray,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'Voice Prompts',
              style: TextStyle(color: mistyGray),
            ),
            value: _useVoicePrompts,
            activeColor: activeBlue,
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
            title: const Text('Chimes', style: TextStyle(color: mistyGray)),
            value: _useChimes,
            activeColor: activeBlue,
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
            title: const Text('Counting', style: TextStyle(color: mistyGray)),
            value: _useCounting,
            activeColor: activeBlue,
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
}

class BreathingBallPainter extends CustomPainter {
  final double progress;
  final double inhaleDuration;
  final double holdAfterInhale;
  final double exhaleDuration;
  final double holdAfterExhale;
  final Color ballColor;

  BreathingBallPainter({
    required this.progress,
    required this.inhaleDuration,
    required this.holdAfterInhale,
    required this.exhaleDuration,
    required this.holdAfterExhale,
    this.ballColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ballColor
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
