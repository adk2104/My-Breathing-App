import 'package:flutter/material.dart';
import 'meditation_screen.dart';

class SlidersScreen extends StatefulWidget {
  const SlidersScreen({super.key});

  @override
  State<SlidersScreen> createState() => _SlidersScreenState();
}

class _SlidersScreenState extends State<SlidersScreen> {
  double meditationDuration = 5; // Total meditation time in minutes
  double inhaleDuration = 4;
  double holdAfterInhale = 2;
  double exhaleDuration = 4;
  double holdAfterExhale = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Breathing Settings'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSlider('Inhale Duration', inhaleDuration, (value) {
              setState(() => inhaleDuration = value);
            }),
            _buildSlider('Hold After Inhale', holdAfterInhale, (value) {
              setState(() => holdAfterInhale = value);
            }),
            _buildSlider('Exhale Duration', exhaleDuration, (value) {
              setState(() => exhaleDuration = value);
            }),
            _buildSlider('Hold After Exhale', holdAfterExhale, (value) {
              setState(() => holdAfterExhale = value);
            }),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24, height: 32),
            _buildSlider(
              'Meditation Duration',
              meditationDuration,
              (value) {
                setState(() => meditationDuration = value);
              },
              minValue: 1,
              maxValue: 30,
              unit: 'min',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MeditationScreen(
                      inhaleDuration: inhaleDuration,
                      holdAfterInhale: holdAfterInhale,
                      exhaleDuration: exhaleDuration,
                      holdAfterExhale: holdAfterExhale,
                      meditationDuration: meditationDuration,
                    ),
                  ),
                );
              },
              child: const Text('Start Meditation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    ValueChanged<double> onChanged, {
    double minValue = 1,
    double maxValue = 10,
    String unit = 's',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toStringAsFixed(1)}$unit',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Slider(
          value: value,
          min: minValue,
          max: maxValue,
          divisions: maxValue.toInt() * 2,
          label: '${value.toStringAsFixed(1)}$unit',
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
