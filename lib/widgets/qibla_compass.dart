import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../services/qibla_api_service.dart';
import '../services/location_service.dart';
import '../localizations/app_localizations.dart';

class QiblaCompass extends StatefulWidget {
  const QiblaCompass({super.key});

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass> {
  double? _direction;
  double? _qiblaDirection;
  bool _isLoading = true;
  String _errorMessage = '';
  final QiblaApiService _qiblaApiService = QiblaApiService();
  final LocationService _locationService = LocationService();
  
  // Add stream subscription to keep track of the compass events
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _fetchQiblaDirection();
    _startListeningToCompass();
  }
  
  @override
  void dispose() {
    // Cancel the compass subscription when the widget is disposed
    _compassSubscription?.cancel();
    super.dispose();
  }

  // Fetch Qibla direction using the user's location
  Future<void> _fetchQiblaDirection() async {
    if (!mounted) return; // Check if widget is still mounted
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current position
      Position? position = await _locationService.getCurrentPosition();
      
      if (!mounted) return; // Check again after async operation
      
      if (position != null) {
        // Get Qibla direction from API
        final qiblaDirection = await _qiblaApiService.getQiblaDirection(
          position.latitude,
          position.longitude,
        );
        
        if (!mounted) return; // Check again after async API call
        
        if (qiblaDirection != null) {
          setState(() {
            _qiblaDirection = qiblaDirection;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = t(context, 'error_qibla_api');
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = t(context, 'error_location');
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Check if still mounted before setting state
      
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Start listening to compass updates
  void _startListeningToCompass() {
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      // Only call setState if the widget is still mounted
      if (mounted) {
        setState(() {
          _direction = event.heading;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchQiblaDirection,
              child: Text(t(context, 'retry')),
            ),
          ],
        ),
      );
    }

    if (_direction == null || _qiblaDirection == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.compass_calibration, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              t(context, 'calibrating_compass') + '\n' + t(context, 'rotate_device_figure_8'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Calculate the angle to rotate the compass
    final double compassAngle = _direction! * (math.pi / 180);
    
    // Calculate the angle to Qibla relative to North
    final double qiblaAngle = (_qiblaDirection! - _direction!) * (math.pi / 180);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t(context, 'qibla_direction_degrees', args: [_qiblaDirection!.toStringAsFixed(1)]),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            // Compass background
            Transform.rotate(
              angle: compassAngle,
              child: SizedBox(
                width: 250,
                height: 250,
                child: CustomPaint(
                  painter: DetailedCompassPainter(),
                ),
              ),
            ),
            // Qibla needle
            Transform.rotate(
              angle: qiblaAngle,
              child: Container(
                height: 120,
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Center dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          t(context, 'point_arrow_to_kaaba'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}

// More detailed compass painter
class DetailedCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Paint for circles
    final circlePaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Paint for degrees tick marks
    final tickPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw outer circle
    canvas.drawCircle(center, radius - 2, circlePaint);
    
    // Draw inner circle
    canvas.drawCircle(center, radius * 0.75, circlePaint);
    
    // Draw text for cardinal points
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Draw N, S, E, W markers
    void drawCardinalPoint(String text, double angle, Color color, double fontSize) {
      final double x = center.dx + (radius - 25) * math.sin(angle);
      final double y = center.dy - (radius - 25) * math.cos(angle);
      
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
    
    // Draw cardinal points
    drawCardinalPoint('N', 0, Colors.red, 20);
    drawCardinalPoint('E', math.pi / 2, Colors.black, 20);
    drawCardinalPoint('S', math.pi, Colors.black, 20);
    drawCardinalPoint('W', 3 * math.pi / 2, Colors.black, 20);
    
    // Draw intercardinal points smaller
    drawCardinalPoint('NE', math.pi / 4, Colors.grey[700]!, 14);
    drawCardinalPoint('SE', 3 * math.pi / 4, Colors.grey[700]!, 14);
    drawCardinalPoint('SW', 5 * math.pi / 4, Colors.grey[700]!, 14);
    drawCardinalPoint('NW', 7 * math.pi / 4, Colors.grey[700]!, 14);
    
    // Draw tick marks for each degree
    for (int i = 0; i < 360; i += 5) {
      final angle = i * math.pi / 180;
      // Longer lines for cardinal and intercardinal points
      final double tickLength = i % 90 == 0 
          ? 15  // N, E, S, W
          : (i % 45 == 0 
              ? 10  // NE, SE, SW, NW
              : (i % 15 == 0 
                  ? 7  // Every 15 degrees
                  : 3));  // Every 5 degrees
      
      final double x1 = center.dx + (radius - 5) * math.sin(angle);
      final double y1 = center.dy - (radius - 5) * math.cos(angle);
      final double x2 = center.dx + (radius - 5 - tickLength) * math.sin(angle);
      final double y2 = center.dy - (radius - 5 - tickLength) * math.cos(angle);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
      
      // Add numbers for major angles (every 30 degrees, except cardinals)
      if (i % 30 == 0 && i % 90 != 0) {
        final double textRadius = radius - 30;
        final double textX = center.dx + textRadius * math.sin(angle);
        final double textY = center.dy - textRadius * math.cos(angle);
        
        textPainter.text = TextSpan(
          text: i.toString(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas, 
          Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 