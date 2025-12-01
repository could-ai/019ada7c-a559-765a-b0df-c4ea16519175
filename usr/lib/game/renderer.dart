import 'package:flutter/material.dart';
import 'math_3d.dart';

class GameRenderer extends CustomPainter {
  final List<GameObject> objects;
  final Camera camera;
  final Color groundColor;

  GameRenderer({
    required this.objects,
    required this.camera,
    required this.groundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.lightBlue.shade100);

    // Sort objects by depth (painter's algorithm)
    // In isometric: depth = x + y + z usually works for simple sorting
    objects.sort((a, b) {
      double depthA = a.position.x + a.position.y + a.position.z;
      double depthB = b.position.x + b.position.y + b.position.z;
      return depthA.compareTo(depthB);
    });

    for (var obj in objects) {
      _drawCube(canvas, size, obj);
    }
  }

  void _drawCube(Canvas canvas, Size size, GameObject obj) {
    // Cube corners relative to center
    double r = 0.5; // radius/half-width
    double h = obj.height; // height

    // Base center
    Vector3 pos = obj.position;
    
    // 8 Corners
    // Bottom Face (z = pos.z)
    Vector3 b1 = Vector3(pos.x - r, pos.y - r, pos.z);
    Vector3 b2 = Vector3(pos.x + r, pos.y - r, pos.z);
    Vector3 b3 = Vector3(pos.x + r, pos.y + r, pos.z);
    Vector3 b4 = Vector3(pos.x - r, pos.y + r, pos.z);
    
    // Top Face (z = pos.z + h)
    Vector3 t1 = Vector3(pos.x - r, pos.y - r, pos.z + h);
    Vector3 t2 = Vector3(pos.x + r, pos.y - r, pos.z + h);
    Vector3 t3 = Vector3(pos.x + r, pos.y + r, pos.z + h);
    Vector3 t4 = Vector3(pos.x - r, pos.y + r, pos.z + h);

    // Project all points
    Offset pb1 = project(b1, camera, size);
    Offset pb2 = project(b2, camera, size);
    Offset pb3 = project(b3, camera, size);
    Offset pb4 = project(b4, camera, size);
    
    Offset pt1 = project(t1, camera, size);
    Offset pt2 = project(t2, camera, size);
    Offset pt3 = project(t3, camera, size);
    Offset pt4 = project(t4, camera, size);

    Paint paint = Paint()..style = PaintingStyle.fill;
    Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black12
      ..strokeWidth = 1.0;

    // Draw faces based on visibility (Isometric assumption: we see Top, Right, Front)
    // Actually, we should draw all needed faces.
    // In standard iso (x-y), we see Top, Right (y-face), Left (x-face) usually?
    // Let's draw Right, Front, Top.

    // Right Face (b2, b3, t3, t2) - actually this depends on rotation.
    // Let's assume standard view.
    
    // Face 1: Right/Bottom-Right (y+)
    Path face1 = Path()..moveTo(pb2.dx, pb2.dy)..lineTo(pb3.dx, pb3.dy)..lineTo(pt3.dx, pt3.dy)..lineTo(pt2.dx, pt2.dy)..close();
    paint.color = _darken(obj.color, 0.2);
    canvas.drawPath(face1, paint);
    canvas.drawPath(face1, borderPaint);

    // Face 2: Left/Bottom-Left (x+)
    Path face2 = Path()..moveTo(pb3.dx, pb3.dy)..lineTo(pb4.dx, pb4.dy)..lineTo(pt4.dx, pt4.dy)..lineTo(pt3.dx, pt3.dy)..close();
    paint.color = _darken(obj.color, 0.4);
    canvas.drawPath(face2, paint);
    canvas.drawPath(face2, borderPaint);

    // Top Face
    Path topFace = Path()..moveTo(pt1.dx, pt1.dy)..lineTo(pt2.dx, pt2.dy)..lineTo(pt3.dx, pt3.dy)..lineTo(pt4.dx, pt4.dy)..close();
    paint.color = obj.color;
    canvas.drawPath(topFace, paint);
    canvas.drawPath(topFace, borderPaint);
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GameObject {
  Vector3 position;
  double height;
  Color color;
  bool isSolid;

  GameObject({
    required this.position,
    this.height = 1.0,
    required this.color,
    this.isSolid = true,
  });
}
