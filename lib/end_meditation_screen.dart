import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'meditation_screen.dart';

class EndMeditationScreen extends StatefulWidget {
  final double inhaleDuration;
  final double holdAfterInhale;
  final double exhaleDuration;
  final double holdAfterExhale;
  final double meditationDuration;

  const EndMeditationScreen({
    super.key,
    required this.inhaleDuration,
    required this.holdAfterInhale,
    required this.exhaleDuration,
    required this.holdAfterExhale,
    required this.meditationDuration,
  });

  @override
  State<EndMeditationScreen> createState() => _EndMeditationScreenState();
}

class _EndMeditationScreenState extends State<EndMeditationScreen> {
  // Define theme colors
  static const deepNavy = Color(0xFF0D1B2A);
  static const mistyGray = Color(0xFFCAD2C5);
  static const buttonBg = Color(0xFF1B263B);
  static const buttonText = Color(0xFFE0FBFC);

  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  void _initAudio() async {
    _audioPlayer = AudioPlayer();
    // Play completion chime
    await _audioPlayer.play(AssetSource('chimes/completion_chime.wav'));
  }

  void _restartMeditation() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MeditationScreen(
          inhaleDuration: widget.inhaleDuration,
          holdAfterInhale: widget.holdAfterInhale,
          exhaleDuration: widget.exhaleDuration,
          holdAfterExhale: widget.holdAfterExhale,
          meditationDuration: widget.meditationDuration,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBg,
          foregroundColor: buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: mistyGray,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Great job!',
                  style: TextStyle(
                    color: mistyGray,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "You've completed your meditation session",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mistyGray, fontSize: 18),
                ),
                const SizedBox(height: 48),
                _buildButton(text: 'Try Again', onPressed: _restartMeditation),
                _buildButton(
                  text: 'Back to Settings',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
