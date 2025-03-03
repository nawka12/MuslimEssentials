// This is a utility script that shows how to create a compass image programmatically.
// You can run this as a standalone Flutter app to generate a compass image,
// or use a design tool to create a more visually appealing compass.

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

// Example usage (not to be included in the actual app)
// void main() {
//   runApp(MaterialApp(
//     home: Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CompassImageGenerator(),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => CompassImageGenerator.saveCompassImage(quality: 4.0),
//               child: const Text('Save High Quality Compass Image'),
//             ),
//           ],
//         ),
//       ),
//     ),
//   ));
// }

class CompassImageGenerator extends StatelessWidget {
  static final GlobalKey _globalKey = GlobalKey();
  final Color backgroundColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Color northTextColor;
  final Color tickColor;
  final bool showOuterDegrees;

  const CompassImageGenerator({
    super.key,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFDDDDDD),
    this.primaryTextColor = Colors.black,
    this.northTextColor = Colors.red,
    this.tickColor = const Color(0xFF555555),
    this.showOuterDegrees = true,
  });

  /// Saves the compass image to the application documents directory
  /// [pixelRatio] determines the quality of the image (higher = better quality but larger file)
  /// [fileName] allows specifying a custom filename (defaults to compass.png)
  /// Returns the path to the saved image
  static Future<String?> saveCompassImage({
    double quality = 3.0,
    String fileName = 'compass.png',
    bool showSaveLocation = true,
  }) async {
    try {
      // Find the render object and convert to image
      RenderRepaintBoundary boundary = 
          _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // Create image with specified quality
      ui.Image image = await boundary.toImage(pixelRatio: quality);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        // Get appropriate directory and save the image
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/$fileName';
        
        await File(imagePath).writeAsBytes(byteData.buffer.asUint8List());
        
        if (showSaveLocation) {
          print('Compass image saved to: $imagePath');
        }
        
        return imagePath;
      }
      return null;
    } catch (e) {
      print('Error saving compass image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
          border: Border.all(color: borderColor, width: 2),
        ),
        child: CustomPaint(
          painter: CompassPainter(
            primaryTextColor: primaryTextColor,
            northTextColor: northTextColor,
            tickColor: tickColor,
            showOuterDegrees: showOuterDegrees,
          ),
        ),
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  final Color primaryTextColor;
  final Color northTextColor;
  final Color tickColor;
  final bool showOuterDegrees;

  CompassPainter({
    this.primaryTextColor = Colors.black,
    this.northTextColor = Colors.red,
    this.tickColor = const Color(0xFF555555),
    this.showOuterDegrees = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Paints for different elements
    final circlePaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final innerCirclePaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final majorTickPaint = Paint()
      ..color = tickColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    final minorTickPaint = Paint()
      ..color = tickColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw outer circle with gradient edge
    final outerGradientPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          Colors.grey[200]!,
          Colors.grey[300]!,
        ],
        [0.95, 1.0],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(center, radius - 5, outerGradientPaint);
    
    // Draw divider circles
    canvas.drawCircle(center, radius * 0.8, innerCirclePaint);
    canvas.drawCircle(center, radius * 0.6, innerCirclePaint);
    
    // Helper function to draw text
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    void drawText(String text, double angle, Color color, double fontSize, {double radiusOffset = 35}) {
      final double x = center.dx + (radius - radiusOffset) * math.sin(angle);
      final double y = center.dy - (radius - radiusOffset) * math.cos(angle);
      
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
    
    // Draw cardinal and intercardinal points
    drawText('N', 0, northTextColor, 26);
    drawText('NE', math.pi / 4, primaryTextColor, 18);
    drawText('E', math.pi / 2, primaryTextColor, 26);
    drawText('SE', 3 * math.pi / 4, primaryTextColor, 18);
    drawText('S', math.pi, primaryTextColor, 26);
    drawText('SW', 5 * math.pi / 4, primaryTextColor, 18);
    drawText('W', 3 * math.pi / 2, primaryTextColor, 26);
    drawText('NW', 7 * math.pi / 4, primaryTextColor, 18);
    
    // Draw secondary intercardinal points (NNE, ENE, etc)
    const secondaryPoints = ['NNE', 'ENE', 'ESE', 'SSE', 'SSW', 'WSW', 'WNW', 'NNW'];
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (math.pi / 8);
      drawText(secondaryPoints[i], angle, primaryTextColor.withOpacity(0.6), 14, radiusOffset: 30);
    }
    
    // Draw tick marks for degrees with varying lengths
    for (int i = 0; i < 360; i += 1) {
      final angle = i * math.pi / 180;
      
      // Determine tick length and paint based on position
      double tickLength;
      Paint tickPaintToUse;
      
      if (i % 90 == 0) {  // N, E, S, W
        tickLength = 18;
        tickPaintToUse = majorTickPaint;
      } else if (i % 45 == 0) {  // NE, SE, SW, NW
        tickLength = 15;
        tickPaintToUse = majorTickPaint;
      } else if (i % 30 == 0) {  // Every 30 degrees
        tickLength = 12;
        tickPaintToUse = majorTickPaint;
      } else if (i % 10 == 0) {  // Every 10 degrees
        tickLength = 10;
        tickPaintToUse = minorTickPaint;
      } else if (i % 5 == 0) {  // Every 5 degrees
        tickLength = 8;
        tickPaintToUse = minorTickPaint;
      } else {  // Every degree
        tickLength = 3;
        tickPaintToUse = minorTickPaint..color = tickColor.withOpacity(0.4);
      }
      
      final double x1 = center.dx + (radius - 5) * math.sin(angle);
      final double y1 = center.dy - (radius - 5) * math.cos(angle);
      final double x2 = center.dx + (radius - 5 - tickLength) * math.sin(angle);
      final double y2 = center.dy - (radius - 5 - tickLength) * math.cos(angle);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaintToUse);
    }
    
    // Draw degree numbers
    if (showOuterDegrees) {
      for (int i = 0; i < 360; i += 30) {
        // Skip cardinal and intercardinal points to avoid text overlap
        if (i % 90 == 0 || i % 45 == 0) continue;
        
        final angle = i * math.pi / 180;
        final String text = i.toString() + '°';
        
        final double x = center.dx + (radius - 22) * math.sin(angle);
        final double y = center.dy - (radius - 22) * math.cos(angle);
        
        textPainter.text = TextSpan(
          text: text,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 12,
          ),
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas, 
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }
    
    // Draw a kaaba symbol in the center
    final kaabaSize = radius * 0.1;
    final rect = Rect.fromCenter(
      center: center, 
      width: kaabaSize, 
      height: kaabaSize
    );
    
    // Rotate the kaaba to face correct orientation
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 4); // Rotate 45 degrees counterclockwise
    canvas.translate(-center.dx, -center.dy);
    
    final kaabaPaint = Paint()
      ..color = primaryTextColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRect(rect, kaabaPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Math helper
class Math {
  static double sin(double angle) => math.sin(angle);
  static double cos(double angle) => math.cos(angle);
} 