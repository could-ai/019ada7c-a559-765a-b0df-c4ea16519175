import 'dart:math';

class Vector3 {
  double x;
  double y;
  double z;

  Vector3(this.x, this.y, this.z);

  Vector3 operator +(Vector3 other) => Vector3(x + other.x, y + other.y, z + other.z);
  Vector3 operator -(Vector3 other) => Vector3(x - other.x, y - other.y, z - other.z);
  Vector3 operator *(double scale) => Vector3(x * scale, y * scale, z * scale);
  
  double distanceTo(Vector3 other) {
    return sqrt(pow(x - other.x, 2) + pow(y - other.y, 2) + pow(z - other.z, 2));
  }
}

class Camera {
  Vector3 position;
  double zoom;
  
  Camera({required this.position, this.zoom = 1.0});
}

// Simple perspective projection
Offset project(Vector3 point, Camera camera, Size screenSize) {
  // Relative position to camera
  double x = point.x - camera.position.x;
  double y = point.y - camera.position.y;
  double z = point.z - camera.position.z;

  // Isometric-ish projection for stability or Perspective
  // Let's do a simple perspective
  // We assume camera is looking slightly down and forward
  
  // Rotate world to simulate camera angle (Pitch ~45 degrees, Yaw ~45 degrees)
  // Isometric projection matrix simulation
  
  double isoX = (x - y) * cos(pi / 6);
  double isoY = (x + y) * sin(pi / 6) - z;

  double centerX = screenSize.width / 2;
  double centerY = screenSize.height / 2;
  
  double scale = 40.0 * camera.zoom; // Base tile size

  return Offset(centerX + isoX * scale, centerY + isoY * scale);
}
