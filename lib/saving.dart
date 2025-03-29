// import 'dart:async';
// import 'dart:math' as math;
// import 'package:flame/collisions.dart';
// import 'package:flame/components.dart';
// import 'package:flame/effects.dart';
// import 'package:flame/events.dart';
// import 'package:flame/game.dart';
// import 'package:flame/sprite.dart';
// import 'package:flame_audio/flame_audio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// const gameWidth = 820.0;
// const gameHeight = 1600.0;
// const ballRadius = gameWidth * 0.03;
// const batWidth = gameWidth * 0.2;
// const batHeight = ballRadius * 2;
// const batStep = gameWidth * 0.05;
// const brickGutter = gameWidth * 0.015;
//
// enum PlayState { welcome, playing, gameOver, won }
// enum Direction { down, left, right, up }
// enum PlayerTurn { player1, player2 }
//
// void main() {
//   runApp(const GameApp());
// }
//
// class PlayArea extends RectangleComponent with HasGameReference<BrickBreaker> {
//   PlayArea()
//       : super(
//     paint: Paint()..color = const Color(0xfff2e8cf),
//     children: [RectangleHitbox()],
//   );
//
//   @override
//   FutureOr<void> onLoad() async {
//     super.onLoad();
//     size = Vector2(game.size.x, game.size.y);
//   }
// }
//
// class BrickBreaker extends FlameGame with HasCollisionDetection, KeyboardEvents, TapDetector {
//   BrickBreaker()
//       : super(
//     camera: CameraComponent.withFixedResolution(
//       width: gameWidth,
//       height: gameHeight,
//     ),
//   );
//
//   final rand = math.Random();
//   late List<Ball> balls;
//   Ball? currentBall;
//   PlayerTurn currentTurn = PlayerTurn.player1;
//   int player1Score = 0;
//   int player2Score = 0;
//   int turnCount = 0;
//   int maxTurns = 10; // Maximum number of turns per player
//   bool gameStarted = false;
//
//   // AI difficulty level (higher = smarter)
//   double aiDifficulty = 0.7;
//
//   late TextComponent turnIndicator;
//   late TextComponent scoreIndicator;
//
//   late PlayState _playState;
//   PlayState get playState => _playState;
//   set playState(PlayState playState) {
//     _playState = playState;
//     switch (playState) {
//       case PlayState.welcome:
//       case PlayState.gameOver:
//       case PlayState.won:
//         overlays.add(playState.name);
//         break;
//       case PlayState.playing:
//         overlays.remove(PlayState.welcome.name);
//         overlays.remove(PlayState.gameOver.name);
//         overlays.remove(PlayState.won.name);
//         break;
//     }
//   }
//
//   @override
//   FutureOr<void> onLoad() async {
//     super.onLoad();
//     // پیش‌بارگذاری فایل‌های صوتی
//     await AudioManager.preloadAll();
//
//     camera.viewfinder.anchor = Anchor.topLeft;
//     world.add(PlayArea());
//
//     // Add turn indicator
//     turnIndicator = TextComponent(
//       text: 'Your Turn',
//       textRenderer: TextPaint(
//         style: const TextStyle(
//           color: Colors.black,
//           fontSize: 30,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       position: Vector2(gameWidth / 2, 50),
//       anchor: Anchor.center,
//     );
//
//     // Add score indicator
//     scoreIndicator = TextComponent(
//       text: 'You: 0 | Enemy: 0',
//       textRenderer: TextPaint(
//         style: const TextStyle(
//           color: Colors.black,
//           fontSize: 24,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       position: Vector2(gameWidth / 2, 100),
//       anchor: Anchor.center,
//     );
//
//     world.add(turnIndicator);
//     world.add(scoreIndicator);
//
//     playState = PlayState.welcome;
//   }
//
//   void startGame() {
//     if (playState == PlayState.playing) return;
//
//     // Remove all overlays first
//     overlays.remove(PlayState.welcome.name);
//     overlays.remove(PlayState.gameOver.name);
//     overlays.remove(PlayState.won.name);
//     overlays.remove('player1Won');
//     overlays.remove('player2Won');
//     overlays.remove('draw');
//
//     // Reset game state
//     world.removeAll(world.children.query<Ball>());
//     player1Score = 0;
//     player2Score = 0;
//     turnCount = 0;
//     currentTurn = PlayerTurn.player1;
//     gameStarted = true;
//
//     playState = PlayState.playing;
//
//     final characterSize = Vector2(ballRadius * 6, ballRadius * 6);
//
//     balls = [
//       Ball(
//         difficultyModifier: 1.03,
//         radius: ballRadius * 2,
//         position: Vector2(gameWidth * 0.3, gameHeight * 0.3),
//         velocity: Vector2((rand.nextDouble() - 0.5) * gameWidth, gameHeight * 0.2)
//             .normalized()
//           ..scale(gameHeight / 4),
//         health: 20,
//         imagePath: 'bahador.png',
//         characterSize: characterSize,
//         columns: 8,
//         rows: 4,
//         player: PlayerTurn.player1,
//       ),
//       Ball(
//         difficultyModifier: 1.03,
//         radius: ballRadius * 2,
//         position: Vector2(gameWidth * 0.7, gameHeight * 0.7),
//         velocity: Vector2((rand.nextDouble() - 0.5) * gameWidth, gameHeight * 0.2)
//             .normalized()
//           ..scale(gameHeight / 4),
//         health: 20,
//         imagePath: 'enemy.png',
//         characterSize: characterSize,
//         columns: 8,
//         rows: 4,
//         player: PlayerTurn.player2,
//       ),
//     ];
//
//     world.add(balls[0]);
//     world.add(balls[1]);
//
//     currentBall = currentTurn == PlayerTurn.player1 ? balls[0] : balls[1];
//     updateTurnIndicator();
//     updateScoreIndicator();
//   }
//
//   void switchTurn() {
//     if (balls.any((ball) => ball.health <= 0)) {
//       endGame();
//       return;
//     }
//
//     // Award points based on damage dealt
//     if (currentTurn == PlayerTurn.player1) {
//       int damageDealt = balls[1].initialHealth - balls[1].health;
//       player1Score += damageDealt;
//       currentTurn = PlayerTurn.player2;
//       turnCount++;
//
//       // AI will play automatically after a short delay
//       Future.delayed(Duration(milliseconds: 1000), () {
//         if (playState == PlayState.playing) {
//           playAITurn();
//         }
//       });
//     } else {
//       int damageDealt = balls[0].initialHealth - balls[0].health;
//       player2Score += damageDealt;
//       currentTurn = PlayerTurn.player1;
//     }
//
//     // Check if max turns reached
//     if (turnCount >= maxTurns) {
//       endGame();
//       return;
//     }
//
//     currentBall = currentTurn == PlayerTurn.player1 ? balls[0] : balls[1];
//
//     // Make sure the current ball is ready for the next turn
//     currentBall!.isMoving = false;
//
//     // Ensure the ball has a valid velocity for the next turn
//     // but don't apply it until the player taps
//     currentBall!.velocity = Vector2(
//         (rand.nextDouble() - 0.5) * gameWidth,
//         (rand.nextDouble() - 0.5) * gameHeight
//     ).normalized()..scale(gameHeight / 4);
//
//     updateTurnIndicator();
//     updateScoreIndicator();
//   }
//
//   // New method for AI to play its turn
//   void playAITurn() {
//     if (currentTurn != PlayerTurn.player2 || playState != PlayState.playing) return;
//
//     final playerBall = balls[0];
//     final aiBall = balls[1];
//
//     // Calculate vector from AI ball to player ball
//     Vector2 directionToPlayer = playerBall.position - aiBall.position;
//
//     // Add some randomness based on AI difficulty (lower difficulty = more random)
//     double randomFactor = 1.0 - aiDifficulty;
//     double randomAngle = (rand.nextDouble() * 2 - 1) * randomFactor * math.pi;
//
//     // Rotate the direction vector by the random angle
//     double currentAngle = math.atan2(directionToPlayer.y, directionToPlayer.x);
//     double newAngle = currentAngle + randomAngle;
//
//     // Set the AI velocity based on the calculated direction
//     aiBall.velocity = Vector2(
//         math.cos(newAngle),
//         math.sin(newAngle)
//     ).normalized()..scale(gameHeight / 4);
//
//     // Start moving the AI ball
//     aiBall.startMoving();
//   }
//
//   void resetBallPositions() {
//     balls[0].position = Vector2(gameWidth * 0.3, gameHeight * 0.3);
//     balls[1].position = Vector2(gameWidth * 0.7, gameHeight * 0.7);
//
//     // Randomize velocities for next turn
//     balls[0].velocity = Vector2((rand.nextDouble() - 0.5) * gameWidth, gameHeight * 0.2)
//         .normalized()
//       ..scale(gameHeight / 4);
//     balls[1].velocity = Vector2((rand.nextDouble() - 0.5) * gameWidth, gameHeight * 0.2)
//         .normalized()
//       ..scale(gameHeight / 4);
//   }
//
//   void updateTurnIndicator() {
//     final playerText = currentTurn == PlayerTurn.player1 ? 'Your Turn' : 'Enemy\'s Turn';
//     final playerColor = currentTurn == PlayerTurn.player1 ? Colors.blue : Colors.red;
//
//     turnIndicator.text = playerText;
//
//     // Force the text to update visually
//     turnIndicator.textRenderer = TextPaint(
//       style: TextStyle(
//         color: playerColor,
//         fontSize: 30,
//         fontWeight: FontWeight.bold,
//       ),
//     );
//   }
//
//   void updateScoreIndicator() {
//     scoreIndicator.text = 'You: $player1Score | Enemy: $player2Score';
//   }
//
//   void endGame() {
//     // Remove any existing game-end overlays first
//     overlays.remove('player1Won');
//     overlays.remove('player2Won');
//     overlays.remove('draw');
//
//     if (balls[0] != null && balls[0].health <= 0) {
//       // پخش صدای باخت
//       FlameAudio.play('lose.mp3');
//       overlays.add('player2Won');
//       pauseEngine();
//     } else if (balls[1] != null && balls[1].health <= 0) {
//       // پخش صدای برد
//       FlameAudio.play('win.mp3');
//       overlays.add('player1Won');
//       pauseEngine();
//     } else if (turnCount >= maxTurns) {
//       // پایان بازی بر اساس امتیاز
//       if (player1Score > player2Score) {
//         // پخش صدای برد
//         FlameAudio.play('win.mp3');
//         overlays.add('player1Won');
//       } else if (player2Score > player1Score) {
//         // پخش صدای باخت
//         FlameAudio.play('lose.mp3');
//         overlays.add('player2Won');
//       } else {
//         // مساوی
//         FlameAudio.play('draw.mp3');
//         overlays.add('draw');
//       }
//       pauseEngine();
//     }
//   }
//
//   @override
//   void onTap() {
//     super.onTap();
//     if (playState == PlayState.welcome) {
//       startGame();
//     } else if (playState == PlayState.playing && currentTurn == PlayerTurn.player1 && currentBall != null && !currentBall!.isMoving) {
//       currentBall!.startMoving();
//     } else if (playState == PlayState.gameOver || playState == PlayState.won) {
//       startGame();
//     }
//   }
//
//   @override
//   KeyEventResult onKeyEvent(
//       KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
//     super.onKeyEvent(event, keysPressed);
//
//     if (event is KeyDownEvent) {
//       switch (event.logicalKey) {
//         case LogicalKeyboardKey.space:
//         case LogicalKeyboardKey.enter:
//           if (playState != PlayState.playing) {
//             startGame();
//           } else if (currentTurn == PlayerTurn.player1 && currentBall != null && !currentBall!.isMoving) {
//             currentBall!.startMoving();
//           }
//           break;
//         case LogicalKeyboardKey.arrowLeft:
//           if (currentTurn == PlayerTurn.player1 && currentBall != null && !currentBall!.isMoving) {
//             currentBall!.velocity = Vector2(-1, 0.5).normalized()..scale(gameHeight / 4);
//           }
//           break;
//         case LogicalKeyboardKey.arrowRight:
//           if (currentTurn == PlayerTurn.player1 && currentBall != null && !currentBall!.isMoving) {
//             currentBall!.velocity = Vector2(1, 0.5).normalized()..scale(gameHeight / 4);
//           }
//           break;
//         case LogicalKeyboardKey.arrowUp:
//           if (currentTurn == PlayerTurn.player1 && currentBall != null && !currentBall!.isMoving) {
//             currentBall!.velocity = Vector2(0, -1).normalized()..scale(gameHeight / 4);
//           }
//           break;
//         case LogicalKeyboardKey.arrowDown:
//           if (currentTurn == PlayerTurn.player1 && currentBall != null && !currentBall!.isMoving) {
//             currentBall!.velocity = Vector2(0, 1).normalized()..scale(gameHeight / 4);
//           }
//           break;
//       }
//     }
//     return KeyEventResult.handled;
//   }
//
//   @override
//   Color backgroundColor() => const Color(0xfff2e8cf);
//
//   @override
//   void update(double dt) {
//     super.update(dt);
//
//     if (playState == PlayState.playing && currentBall != null) {
//       handleBallCollisions(dt);
//     }
//   }
//
//   void handleBallCollisions(double dt) {
//     if (!gameStarted || balls.length < 2) return;
//
//     final otherBall = currentBall == balls[0] ? balls[1] : balls[0];
//
//     if (currentBall!.isMoving && currentBall!.toRect().overlaps(otherBall.toRect())) {
//
//       AudioManager.playSound('collision.mp3');
//
//       // Calculate collision normal
//       Vector2 normal = currentBall!.position - otherBall.position;
//
//       // Prevent zero normal vector
//       if (normal.length2 < 0.0001) {
//         // If balls are exactly at the same position, move one slightly
//         normal = Vector2(1, 0); // Default direction
//       }
//
//       normal.normalize();
//
//       // Apply collision response
//       currentBall!.velocity = currentBall!.velocity.reflected(normal);
//
//       // Move the current ball away from the other ball to prevent sticking
//       final pushDistance = (currentBall!.width/2 + otherBall.width/2) * 1.2; // Add 20% extra distance
//       Vector2 pushVector = normal.clone()..scale(pushDistance);
//       currentBall!.position = otherBall.position + pushVector;
//
//       // Make sure velocity is significant after collision
//       if (currentBall!.velocity.length < gameHeight / 8) {
//         currentBall!.velocity.scale(gameHeight / 8 / currentBall!.velocity.length);
//         // currentBall!.velocity.scale(gameHeight / 8 / currentBall!.velocity.length);
//         }
//
//             // Apply damage to the other ball
//             otherBall.decreaseHealth(5); // Increased damage for better gameplay
//
//         // Add visual feedback for collision - using a flash effect that automatically removes itself
//         otherBall.flash();
//
//         // Add score based on collision
//         if (currentTurn == PlayerTurn.player1) {
//           player1Score += 1;
//         } else {
//           player2Score += 1;
//         }
//
//         updateScoreIndicator();
//       }
//     }
//
// }
//
// class Ball extends SpriteAnimationComponent
//     with CollisionCallbacks, HasGameReference<BrickBreaker> {
//   Ball({
//     required this.velocity,
//     required super.position,
//     required double radius,
//     required this.difficultyModifier,
//     required this.health,
//     required this.imagePath,
//     required this.characterSize,
//     required this.columns,
//     required this.rows,
//     required this.player,
//   }) :
//         initialHealth = health,
//         super(
//         size: characterSize,
//         anchor: Anchor.center,
//         children: [CircleHitbox(radius: radius)],
//       );
//
//   Vector2 velocity;
//   final double difficultyModifier;
//   bool isMoving = false;
//   double moveTime = 0;
//   int health;
//   final int initialHealth;
//   final String imagePath;
//   final Vector2 characterSize;
//   final int columns;
//   final int rows;
//   final PlayerTurn player;
//   Direction direction = Direction.down;
//   late SpriteSheet spriteSheet;
//
//   // Health bar properties
//   final Paint _healthBarBgPaint = Paint()..color = Colors.grey.shade800;
//   final Paint _healthBarFgPaint = Paint()..color = Colors.green;
//   final double _healthBarHeight = 10.0;
//   final double _healthBarWidth = 100.0;
//
//
//   // For flash effect
//   bool isFlashing = false;
//   double flashTime = 0.0;
//   final double flashDuration = 0.2;
//
//   @override
//   Future<void> onLoad() async {
//     await super.onLoad();
//
//     try {
//       spriteSheet = SpriteSheet(
//         image: await game.images.load(imagePath),
//         srcSize: Vector2(
//           (await game.images.load(imagePath)).width / columns.toDouble(),
//           (await game.images.load(imagePath)).height / rows.toDouble(),
//         ),
//       );
//
//       animation = spriteSheet.createAnimation(row: 0, stepTime: 0.2);
//     } catch (e) {
//       print('Error loading sprite sheet: $e');
//       // Fallback to a colored circle if image loading fails
//       final circleRenderComponent = CircleComponent(
//         radius: width / 2,
//         paint: Paint()..color = player == PlayerTurn.player1 ? Colors.blue : Colors.red,
//       );
//       add(circleRenderComponent);
//     }
//   }
//
//   @override
//   void update(double dt) {
//     super.update(dt);
//
//     // Handle flash effect
//     if (isFlashing) {
//       flashTime -= dt;
//       if (flashTime <= 0) {
//         isFlashing = false;
//         // Reset the paint to normal
//         paint = Paint()..color = Colors.white;
//         opacity = 1.0;
//       }
//     }
//
//     if (isMoving) {
//       // Update direction based on velocity
//       if (velocity.x.abs() > velocity.y.abs()) {
//         direction = velocity.x > 0 ?
//         Direction.right : Direction.left;
//       } else {
//         direction = velocity.y > 0 ?
//         Direction.down : Direction.up;
//       }
//
//       updateAnimation();
//
//       // Only move if velocity is not zero
//       if (velocity.length2 > 0) {
//         position += velocity * dt;
//       }
//
//       moveTime -= dt;
//
//       if (moveTime <= 0) {
//         isMoving = false;
//         game.switchTurn();
//       }
//
//       // Wall collision
//       if (position.x - width / 2 <= 0) {
//         position.x = width / 2;
//         velocity.x = -velocity.x;
//       } else if (position.x + width / 2 >= game.size.x) {
//         position.x = game.size.x - width / 2;
//         velocity.x = -velocity.x;
//       }
//
//       if (position.y - height / 2 <= 0) {
//         position.y = height / 2;
//         velocity.y = -velocity.y;
//       } else if (position.y + height / 2 >= game.size.y) {
//         position.y = game.size.y - height / 2;
//         velocity.y = -velocity.y;
//       }
//     }
//   }
//
//   void updateAnimation() {
//     int row = 0;
//     switch (direction) {
//       case Direction.down:
//         row = 0;
//         break;
//       case Direction.up:
//         row = 1;
//         break;
//       case Direction.left:
//         row = 2;
//         break;
//       case Direction.right:
//         row = 3;
//         break;
//     }
//
//     animation = spriteSheet.createAnimation(row: row, stepTime: 0.1);
//   }
//
//   void startMoving() {
//     // Reset any previous state
//     isMoving = true;
//     moveTime = 5; // Reduced move time for faster turns
//
//     // Make sure velocity is not zero
//     if (velocity.length2 < 0.1) {
//       // Set a default velocity if it's zero or very small
//       velocity = Vector2(
//           (game.rand.nextDouble() - 0.5) * gameWidth,
//           (game.rand.nextDouble() - 0.5) * gameHeight
//       ).normalized()..scale(gameHeight / 4);
//     }
//
//     // Add visual effect when starting to move
//     add(
//       ScaleEffect.by(
//         Vector2.all(1.2),
//         EffectController(duration: 0.2, reverseDuration: 0.2),
//       ),
//     );
//   }
//
//   void decreaseHealth(int damage) {
//     health -= damage;
//     if (health < 0) health = 0;
//
//     // Add visual feedback for damage
//     add(
//       MoveByEffect(
//         Vector2(10, 0),
//         EffectController(duration: 0.1, reverseDuration: 0.1),
//       ),
//     );
//   }
//
//   // New method for flash effect
//   void flash() {
//     isFlashing = true;
//     flashTime = flashDuration;
//
//     // پخش صدای برخورد
//     FlameAudio.play('collision.mp3');
//
//     // Set white flash
//     paint = Paint()..color = Colors.white;
//     opacity = 0.8;
//
//     // Add a scale effect for impact
//     add(
//       ScaleEffect.by(
//         Vector2.all(1.3),
//         EffectController(duration: 0.1, reverseDuration: 0.1),
//       ),
//     );
//   }
//
//   @override
//   void render(Canvas canvas) {
//     super.render(canvas);
//
//     // Draw health bar
//     final healthBarRect = Rect.fromLTWH(
//       -_healthBarWidth / 2,
//       -height / 2 - 20,
//       _healthBarWidth,
//       _healthBarHeight,
//     );
//
//     // Background of health bar
//     canvas.drawRect(healthBarRect, _healthBarBgPaint);
//
//     // Foreground of health bar (actual health)
//     final healthPercentage = health / initialHealth;
//     final healthBarFgRect = Rect.fromLTWH(
//       -_healthBarWidth / 2,
//       -height / 2 - 20,
//       _healthBarWidth * healthPercentage,
//       _healthBarHeight,
//     );
//
//     // Change color based on health percentage
//     if (healthPercentage > 0.6) {
//       _healthBarFgPaint.color = Colors.green;
//     } else if (healthPercentage > 0.3) {
//       _healthBarFgPaint.color = Colors.orange;
//     } else {
//       _healthBarFgPaint.color = Colors.red;
//     }
//
//     canvas.drawRect(healthBarFgRect, _healthBarFgPaint);
//
//     // Draw health text
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text: health.toString(),
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//           shadows: [
//             Shadow(
//               blurRadius: 2.0,
//               color: Colors.black,
//               offset: Offset(1.0, 1.0),
//             ),
//           ],
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(
//       canvas,
//       Offset(-textPainter.width / 2, -height / 2 - 45),
//     );
//
//     // Draw player indicator
//     final playerText = player == PlayerTurn.player1 ? "YOU" : "ENEMY";
//     final playerTextPainter = TextPainter(
//       text: TextSpan(
//         text: playerText,
//         style: TextStyle(
//           color: player == PlayerTurn.player1 ? Colors.blue : Colors.red,
//           fontSize: 24,
//           fontWeight: FontWeight.bold,
//           shadows: [
//             Shadow(
//               blurRadius: 2.0,
//               color: Colors.black,
//               offset: Offset(1.0, 1.0),
//             ),
//           ],
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     playerTextPainter.layout();
//     playerTextPainter.paint(
//       canvas,
//       Offset(-playerTextPainter.width / 2, height / 2 + 10),
//     );
//   }
// }
//
// class GameApp extends StatelessWidget {
//   const GameApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         textTheme: GoogleFonts.pressStart2pTextTheme().apply(
//           bodyColor: const Color(0xff184e77),
//           displayColor: const Color(0xff184e77),
//         ),
//       ),
//       home: Scaffold(
//         body: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 Color(0xffa9d6e5),
//                 Color(0xfff2e8cf),
//               ],
//             ),
//           ),
//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(0),
//               child: Center(
//                 child: FittedBox(
//                   child: SizedBox(
//                     width: gameWidth,
//                     height: gameHeight,
//                     child: GameWidget.controlled(
//                       gameFactory: BrickBreaker.new,
//                       overlayBuilderMap: {
//                         PlayState.welcome.name: (context, game) => WelcomeOverlay(),
//                         PlayState.gameOver.name: (context, game) => GameOverOverlay(game as BrickBreaker),
//                         PlayState.won.name: (context, game) => WinnerOverlay(game as BrickBreaker),
//                         'player1Won': (context, game) => PlayerWonOverlay(1, game as BrickBreaker),
//                         'player2Won': (context, game) => PlayerWonOverlay(2, game as BrickBreaker),
//                         'draw': (context, game) => DrawOverlay(),
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class WelcomeOverlay extends StatelessWidget {
//   const WelcomeOverlay({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.black.withOpacity(0.9),
//       child: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'BATTLE GAME',
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 40,
//                 color: Colors.white,
//                 shadows: [
//                   Shadow(
//                     blurRadius: 10.0,
//                     color: Colors.blue,
//                     offset: Offset(0, 0),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 50),
//             Text(
//               'TAP TO START',
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 24,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 30),
//             Container(
//               width: gameWidth * 0.8,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Column(
//                 children: [
//                   Text(
//                     'HOW TO PLAY:',
//                     style: GoogleFonts.pressStart2p(
//                       fontSize: 18,
//                       color: Colors.yellow,
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   Text(
//                     '- Tap to launch your character\n'
//                         '- Use arrow keys to aim\n'
//                         '- Hit your opponent to deal damage\n'
//                         '- First to reduce opponent\'s health to 0 wins\n'
//                         '- Game ends after 10 turns',
//                     style: GoogleFonts.pressStart2p(
//                       fontSize: 14,
//                       color: Colors.white,
//                       height: 1.5,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton.icon(
//               onPressed: () {
//                 AudioManager.toggleSound();
//                 // برای نمایش تغییر وضعیت می‌توانیم از setState استفاده کنیم
//               },
//               icon: Icon(
//                 AudioManager.isSoundEnabled ? Icons.volume_up : Icons.volume_off,
//                 color: Colors.white,
//               ),
//               label: Text(
//                 AudioManager.isSoundEnabled ? 'Sound: ON' : 'Sound: OFF',
//                 style: GoogleFonts.pressStart2p(
//                   fontSize: 14,
//                   color: Colors.white,
//                 ),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue.withOpacity(0.3),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class GameOverOverlay extends StatelessWidget {
//   final BrickBreaker game;
//
//   const GameOverOverlay(this.game, {super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.black.withOpacity(0.7),
//       child: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'GAME OVER',
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 40,
//                 color: Colors.red,
//                 shadows: [
//                   Shadow(
//                     blurRadius: 10.0,
//                     color: Colors.red.shade900,
//                     offset: Offset(0, 0),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             Text(
//               'FINAL SCORE',
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 24,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Column(
//                   children: [
//                     Text(
//                       'YOU',
//                       style: GoogleFonts.pressStart2p(
//                         fontSize: 18,
//                         color: Colors.blue,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       '${game.player1Score}',
//                       style: GoogleFonts.pressStart2p(
//                         fontSize: 30,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(width: 80),
//                 Column(
//                   children: [
//                     Text(
//                       'ENEMY',
//                       style: GoogleFonts.pressStart2p(
//                         fontSize: 18,
//                         color: Colors.red,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       '${game.player2Score}',
//                       style: GoogleFonts.pressStart2p(
//                         fontSize: 30,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 50),
//             Text(
//               'TAP TO PLAY AGAIN',
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 18,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class WinnerOverlay extends StatelessWidget {
//   final BrickBreaker game;
//
//   const WinnerOverlay(this.game, {super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final winner = game.player1Score > game.player2Score ? 1 : 2;
//     final winnerColor = winner == 1 ? Colors.blue : Colors.red;
//     final winnerText = winner == 1 ? 'YOU WIN!' : 'ENEMY WINS!';
//
//     return Container(
//       color: Colors.black.withOpacity(0.7),
//       child: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               winnerText,
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 36,
//                 color: winnerColor,
//                 shadows: [
//                   Shadow(
//                     blurRadius: 10.0,
//                     color: winnerColor.withOpacity(0.7),
//                     offset: Offset(0, 0),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             Text(
//               'FINAL SCORE',
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 24,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Column(
//                   children: [
//                     Text(
//                       'YOU',
//                       style: GoogleFonts.pressStart2p(
//                         fontSize: 18,
//                         color: Colors.blue,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       '${game.player1Score}',
//                       style: GoogleFonts.pressStart2p(
//                         fontSize: 30,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(width: 80),
//                 Column(
//                   children: [
//                     Text(
//                       'ENEMY',
//                       style: GoogleFonts.pressStart2p(
//                         fontSize: 18,
//                         color: Colors.red,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       '${game.player2Score}',
//                       style: GoogleFonts.pressStart2p(
//                         fontSize: 30,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 50),
//             Text(
//               'TAP TO PLAY AGAIN',
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 18,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class PlayerWonOverlay extends StatelessWidget {
//   final int playerNumber;
//   final BrickBreaker game;
//   const PlayerWonOverlay(this.playerNumber, this.game, {super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final winnerColor = playerNumber == 1 ? Colors.blue : Colors.red;
//     final winnerText = playerNumber == 1 ? 'YOU WIN!' : 'ENEMY WINS!';
//
//     return Container(
//       color: Colors.black.withOpacity(0.7),
//       child: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               winnerText,
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 36,
//                 color: winnerColor,
//                 shadows: [
//                   Shadow(
//                     blurRadius: 10.0,
//                     color: winnerColor.withOpacity(0.7),
//                     offset: Offset(0, 0),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             Text(
//               'FINAL SCORE',
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 24,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Column(
//                   children: [
//                     Text(
//                       'YOU',
//                       style: GoogleFonts.pressStart2p(
//                         fontSize: 18,
//                         color: Colors.blue,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       '${game.player1Score}',
//                       style: GoogleFonts.pressStart2p(
//                         fontSize: 30,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(width: 80),
//                 Column(
//                   children: [
//                     Text(
//                       'ENEMY',
//                       style: GoogleFonts.pressStart2p(
//                         fontSize: 18,
//                         color: Colors.red,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       '${game.player2Score}',
//                       style: GoogleFonts.pressStart2p(
//                         fontSize: 30,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 40),
//             Container(
//               padding: EdgeInsets.all(15),
//               decoration: BoxDecoration(
//                 color: winnerColor.withOpacity(0.3),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Text(
//                 playerNumber == 1 ? 'VICTORY!' : 'DEFEAT!',
//                 style: GoogleFonts.pressStart2p(
//                   fontSize: 24,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 50),
//             Text(
//               'TAP TO PLAY AGAIN',
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 18,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class DrawOverlay extends StatelessWidget {
//   const DrawOverlay({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.black.withOpacity(0.7),
//       child: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'IT\'S A DRAW!',
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 36,
//                 color: Colors.yellow,
//                 shadows: [
//                   Shadow(
//                     blurRadius: 10.0,
//                     color: Colors.yellow.withOpacity(0.7),
//                     offset: Offset(0, 0),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             Text(
//               'TIED MATCH',
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 20,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 50),
//             Container(
//               padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Text(
//                 'REMATCH?',
//                 style: GoogleFonts.pressStart2p(
//                   fontSize: 24,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 50),
//             Text(
//               'TAP TO PLAY AGAIN',
//               style: GoogleFonts.pressStart2p(
//                 fontSize: 18,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class AudioManager {
//   static bool isSoundEnabled = true;
//
//   static Future<void> preloadAll() async {
//     await FlameAudio.audioCache.loadAll([
//       'collision.mp3',
//       'launch.mp3',
//       'win.mp3',
//       'lose.mp3',
//     ]);
//   }
//
//   static void playSound(String sound) {
//     if (isSoundEnabled) {
//       FlameAudio.play(sound);
//     }
//   }
//
//   static void toggleSound() {
//     isSoundEnabled = !isSoundEnabled;
//   }
// }
//
//
//
//
//
//
//
