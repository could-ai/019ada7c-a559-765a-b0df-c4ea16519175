import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'math_3d.dart';
import 'renderer.dart';
import 'joystick.dart';
import 'dart:math';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  
  // Game State
  late Camera _camera;
  late GameObject _player;
  List<GameObject> _worldObjects = [];
  Offset _inputVector = Offset.zero;
  
  // Level Data (1 = Wall, 0 = Floor, 2 = Goal)
  final List<List<int>> _levelMap = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 1, 2, 0, 1],
    [1, 0, 1, 1, 0, 0, 1, 0, 0, 1],
    [1, 0, 1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 0, 1, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 0, 1, 1, 0, 1],
    [1, 0, 0, 0, 1, 0, 0, 0, 0, 1],
    [1, 1, 1, 0, 0, 0, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ];

  bool _hasWon = false;

  @override
  void initState() {
    super.initState();
    _initGame();
    _ticker = createTicker(_gameLoop)..start();
  }

  void _initGame() {
    _player = GameObject(
      position: Vector3(1.5, 1.5, 0),
      color: Colors.blue,
      height: 0.8,
    );

    _camera = Camera(position: Vector3(1.5, 1.5, 0), zoom: 1.2);
    _buildLevel();
    _hasWon = false;
  }

  void _buildLevel() {
    _worldObjects.clear();
    // Add Floor
    for (int x = 0; x < _levelMap.length; x++) {
      for (int y = 0; y < _levelMap[x].length; y++) {
        // Floor tile
        _worldObjects.add(GameObject(
          position: Vector3(x.toDouble(), y.toDouble(), -1.0),
          height: 1.0, // Floor thickness
          color: (x + y) % 2 == 0 ? Colors.green.shade300 : Colors.green.shade400,
          isSolid: false,
        ));

        int type = _levelMap[x][y];
        if (type == 1) {
          // Wall
          _worldObjects.add(GameObject(
            position: Vector3(x.toDouble(), y.toDouble(), 0),
            height: 1.5,
            color: Colors.grey.shade700,
            isSolid: true,
          ));
        } else if (type == 2) {
          // Goal
          _worldObjects.add(GameObject(
            position: Vector3(x.toDouble(), y.toDouble(), 0),
            height: 0.5,
            color: Colors.amber,
            isSolid: false,
          ));
        }
      }
    }
  }

  void _gameLoop(Duration elapsed) {
    if (_hasWon) return;

    double speed = 0.1;
    
    // Calculate new position
    double dx = _inputVector.dx * speed;
    double dy = _inputVector.dy * speed;

    // Simple Collision Detection
    double nextX = _player.position.x + dx;
    double nextY = _player.position.y + dy;

    if (!_checkCollision(nextX, _player.position.y)) {
      _player.position.x = nextX;
    }
    if (!_checkCollision(_player.position.x, nextY)) {
      _player.position.y = nextY;
    }

    // Camera follow player (smooth)
    _camera.position.x += (_player.position.x - _camera.position.x) * 0.1;
    _camera.position.y += (_player.position.y - _camera.position.y) * 0.1;

    // Check Win Condition
    _checkWin();

    setState(() {});
  }

  bool _checkCollision(double x, double y) {
    // Check boundaries of grid
    if (x < 0 || y < 0 || x >= _levelMap.length || y >= _levelMap[0].length) return true;
    
    // Check walls
    int gridX = x.round();
    int gridY = y.round();
    
    if (gridX >= 0 && gridX < _levelMap.length && gridY >= 0 && gridY < _levelMap[0].length) {
      if (_levelMap[gridX][gridY] == 1) {
        // Simple radius check
        double dist = sqrt(pow(x - gridX, 2) + pow(y - gridY, 2));
        if (dist < 0.7) return true; // Collision radius
      }
    }
    return false;
  }

  void _checkWin() {
    int gridX = _player.position.x.round();
    int gridY = _player.position.y.round();
    
    if (_levelMap[gridX][gridY] == 2) {
      setState(() {
        _hasWon = true;
      });
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('مبروك!'),
        content: const Text('لقد وجدت الكنز!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initGame();
              setState(() {});
            },
            child: const Text('العب مرة أخرى'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Combine static world objects with dynamic player
    List<GameObject> renderList = [..._worldObjects, _player];

    return Scaffold(
      body: Stack(
        children: [
          // 3D View
          Positioned.fill(
            child: CustomPaint(
              painter: GameRenderer(
                objects: renderList,
                camera: _camera,
                groundColor: Colors.green,
              ),
            ),
          ),
          
          // UI Layer
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "مغامرة المكعب",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () {
                          _initGame();
                          setState(() {});
                        },
                      )
                    ],
                  ),
                ),
                const Spacer(),
                // Controls
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Joystick(
                        onChange: (offset) {
                          // Rotate input to match isometric view
                          // Up on joystick should mean "Up-Right" in screen space (which is +X +Y in grid?)
                          // Let's adjust:
                          // Joystick Up (dy < 0) -> Move "North" in world
                          // In our Iso projection:
                          // X axis goes Bottom-Left to Top-Right
                          // Y axis goes Top-Left to Bottom-Right
                          
                          // Let's map joystick directly to X/Y for now and adjust feel
                          _inputVector = offset;
                        },
                      ),
                      // Action Button (Jump/Interact - Placeholder)
                      FloatingActionButton(
                        onPressed: () {
                          // Jump logic could go here
                        },
                        backgroundColor: Colors.amber,
                        child: const Icon(Icons.arrow_upward),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
