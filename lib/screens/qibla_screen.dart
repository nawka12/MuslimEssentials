import 'package:flutter/material.dart';
import '../widgets/qibla_compass.dart';
import '../localizations/app_localizations.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'qibla_direction')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                t(context, 'qibla_finder'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t(context, 'find_kaaba_direction'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // The QiblaCompass widget takes most of the screen
              const Expanded(
                child: QiblaCompass(),
              ),
              const SizedBox(height: 16),
              Text(
                t(context, 'magnetic_interference_warning'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 