import 'dart:async';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:gamemvp/play_area.dart';

import 'audio_manager.dart';
import 'ball.dart';
import 'enums.dart';

class BrickBreaker extends FlameGame with HasCollisionDetection, TapDetector {
  BrickBreaker()
      : super(
    camera: CameraComponent.withFixedResolution(
      width: gameWidth,
      height: gameHeight,
    ),
  );

  final rand = math.Random();
  late List<Ball> balls;
  Ball? currentBall;
  PlayerTurn currentTurn = PlayerTurn.player1;
  int player1Score = 0;
  int player2Score = 0;
  int turnCount = 0;
  int maxTurns = 10;
  bool gameStarted = false;
  double aiDifficulty = 0.7;

  // متغیرهای جدید برای ذخیره اطلاعات دور قبلی
  AIBehavior _lastAIBehavior = AIBehavior.aggressive;
  Vector2 _lastAIDirection = Vector2.zero();
  double _lastAISpeed = 0;


  late TextComponent turnIndicator;
  late TextComponent scoreIndicator;

  late PlayState _playState;
  PlayState get playState => _playState;
  set playState(PlayState playState) {
    _playState = playState;
    switch (playState) {
      case PlayState.welcome:
      case PlayState.gameOver:
      case PlayState.won:
        overlays.add(playState.name);
        break;
      case PlayState.playing:
        overlays.remove(PlayState.welcome.name);
        overlays.remove(PlayState.gameOver.name);
        overlays.remove(PlayState.won.name);
        break;
    }
  }

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    await AudioManager.preloadAll();

    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(PlayArea() as Component);

    turnIndicator = TextComponent(
      text: 'Your Turn',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(gameWidth / 2, 50),
      anchor: Anchor.center,
    );

    scoreIndicator = TextComponent(
      text: 'You: 0 | Enemy: 0',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(gameWidth / 2, 100),
      anchor: Anchor.center,
    );

    world.add(turnIndicator);
    world.add(scoreIndicator);

    playState = PlayState.welcome;
  }

  void switchTurn() {
    if (balls.any((ball) => ball.health <= 0)) {
      endGame();
      return;
    }

    if (currentTurn == PlayerTurn.player1) {
      int damageDealt = balls[1].initialHealth - balls[1].health;
      player1Score += damageDealt;
      currentTurn = PlayerTurn.player2;
      turnCount++;

      Future.delayed(Duration(milliseconds: 1000), () {
        if (playState == PlayState.playing) {
          playAITurn();
        }
      });
    } else {
      int damageDealt = balls[0].initialHealth - balls[0].health;
      player2Score += damageDealt;
      currentTurn = PlayerTurn.player1;
    }

    if (turnCount >= maxTurns) {
      endGame();
      return;
    }

    currentBall = currentTurn == PlayerTurn.player1 ? balls[0] : balls[1];
    currentBall!.isMoving = false; // توقف حرکت کاراکتر
    currentBall!.velocity = Vector2(
      (rand.nextDouble() - 0.5) * gameWidth,
      (rand.nextDouble() - 0.5) * gameHeight,
    ).normalized()..scale(gameHeight / 4);

    updateTurnIndicator();
    updateScoreIndicator();
  }

  void playAITurn() {
    if (currentTurn != PlayerTurn.player2 || playState != PlayState.playing) return;

    final playerBall = balls[0];
    final aiBall = balls[1];

    // ===== تحلیل وضعیت بازی =====
    final healthDifference = aiBall.health - playerBall.health;
    final distanceToPlayer = (playerBall.position - aiBall.position).length;
    final playerVelocity = playerBall.velocity.clone();
    final playerSpeed = playerVelocity.length;
    final playerDirection = playerVelocity.normalized();
    final directionToPlayer = (playerBall.position - aiBall.position).normalized();

    // محاسبه زمان تقریبی برخورد با بازیکن
    final timeToCollision = distanceToPlayer / (gameHeight / 4);

    // محاسبه فاصله از دیوارها
    final distanceToLeftWall = aiBall.position.x - aiBall.width / 2;
    final distanceToRightWall = gameWidth - aiBall.position.x - aiBall.width / 2;
    final distanceToTopWall = aiBall.position.y - aiBall.height / 2;
    final distanceToBottomWall = gameHeight - aiBall.position.y - aiBall.height / 2;
    final minWallDistance = math.min(
        math.min(distanceToLeftWall, distanceToRightWall),
        math.min(distanceToTopWall, distanceToBottomWall)
    );

    // ===== تعیین استراتژی بر اساس وضعیت بازی =====
    AIBehavior currentBehavior;
    double targetSpeed;
    Vector2 targetDirection = Vector2.zero();

    // تنظیم دشواری پویا - افزایش دشواری کلی
    double dynamicDifficulty = aiDifficulty * 1.2; // افزایش 20% در دشواری پایه

    // افزایش دشواری در دورهای پایانی
    final endgameFactor = math.max(0, 1 - (maxTurns - turnCount) / maxTurns);
    dynamicDifficulty += endgameFactor * 0.4; // افزایش بیشتر در دورهای پایانی

    // افزایش دشواری با کاهش سلامتی AI - حالت "آخرین تلاش" قوی‌تر
    final healthRatio = aiBall.health / aiBall.initialHealth;
    if (healthRatio < 0.5) dynamicDifficulty += 0.25; // افزایش بیشتر در سلامتی پایین

    // محدود کردن دشواری نهایی - افزایش حد بالا
    dynamicDifficulty = math.min(math.max(dynamicDifficulty, 0.4), 0.98);

    // ===== انتخاب رفتار هوشمند - تمرکز بر حمله =====
    if (minWallDistance < 80) {
      // فقط اگر خیلی نزدیک دیوار است، حالت فرار
      currentBehavior = AIBehavior.evasive;
    } else if (healthDifference < -30 || turnCount > maxTurns * 0.8) {
      // اگر خیلی عقب است یا در دورهای پایانی، حالت حمله شدید
      currentBehavior = AIBehavior.superAggressive;
    } else {
      // در اکثر موارد، حمله استاندارد یا حمله هوشمند
      currentBehavior = distanceToPlayer < 200 ? AIBehavior.superAggressive : AIBehavior.aggressive;
    }

    // تصمیم‌گیری تصادفی کمتر (فقط 5% شانس)
    if (rand.nextDouble() < 0.05) {
      final behaviors = [AIBehavior.aggressive, AIBehavior.superAggressive, AIBehavior.evasive];
      currentBehavior = behaviors[rand.nextInt(behaviors.length)];
    }

    // ===== اجرای استراتژی انتخاب شده =====
    switch (currentBehavior) {
      case AIBehavior.superAggressive:
      // حمله شدید: حمله مستقیم با سرعت بالا و پیش‌بینی دقیق‌تر

      // پیش‌بینی پیشرفته حرکت بازیکن
        Vector2 predictedPosition;
        if (playerSpeed > 0) {
          // پیش‌بینی موقعیت بازیکن با در نظر گرفتن برخورد احتمالی با دیوارها
          predictedPosition = _predictPlayerPosition(playerBall, timeToCollision * 0.7);
        } else {
          predictedPosition = playerBall.position;
        }

        // محاسبه جهت به سمت موقعیت پیش‌بینی شده
        targetDirection = (predictedPosition - aiBall.position).normalized();

        // سرعت بالاتر برای حمله شدید
        targetSpeed = gameHeight / 4 * (0.9 + dynamicDifficulty * 0.5);
        break;

      case AIBehavior.aggressive:
      // حمله استاندارد: تعادل بین سرعت و دقت

      // ترکیب حمله مستقیم با کمی پیش‌بینی
        Vector2 basicDirection = directionToPlayer;
        Vector2 predictiveDirection = Vector2.zero();

        if (playerSpeed > 0) {
          // پیش‌بینی ساده‌تر
          final predictedPosition = playerBall.position + playerVelocity * timeToCollision * 0.4;
          predictiveDirection = (predictedPosition - aiBall.position).normalized();
        } else {
          predictiveDirection = directionToPlayer;
        }

        // ترکیب 60% پیش‌بینی، 40% حمله مستقیم
        targetDirection = predictiveDirection.scaled(0.6) + basicDirection.scaled(0.4);
        targetDirection = targetDirection.normalized();

        // سرعت متوسط رو به بالا
        targetSpeed = gameHeight / 4 * (0.75 + dynamicDifficulty * 0.4);
        break;

      case AIBehavior.evasive:
      // حالت فرار: فقط برای دور شدن از دیوارها و بازگشت سریع به حمله
        targetDirection = Vector2.zero();

        // دور شدن از دیوارها
        if (distanceToLeftWall < 100) targetDirection.x += 2;
        if (distanceToRightWall < 100) targetDirection.x -= 2;
        if (distanceToTopWall < 100) targetDirection.y += 2;
        if (distanceToBottomWall < 100) targetDirection.y -= 2;

        // ترکیب با حرکت به سمت بازیکن برای حفظ حالت تهاجمی حتی در فرار
        if (targetDirection.length > 0) {
          targetDirection = targetDirection.normalized().scaled(0.7) + directionToPlayer.scaled(0.3);
        } else {
          targetDirection = directionToPlayer;
        }

        targetDirection = targetDirection.normalized();
        targetSpeed = gameHeight / 4 * (0.7 + dynamicDifficulty * 0.3);
        break;

      }

    // ===== اعمال تصادفی‌سازی کمتر برای حملات دقیق‌تر =====
    // کاهش میزان تصادفی‌سازی
    final randomFactor = math.max(0.05, 0.8 - dynamicDifficulty);

    // زاویه تصادفی کوچک‌تر
    final randomAngle = (rand.nextDouble() * 2 - 1) * randomFactor * math.pi * 0.3;
    final currentAngle = math.atan2(targetDirection.y, targetDirection.x);
    final newAngle = currentAngle + randomAngle;

    // اعمال جهت نهایی
    final finalDirection = Vector2(math.cos(newAngle), math.sin(newAngle)).normalized();

    // ===== اعمال تنظیمات نهایی =====
    // تنظیم سرعت با تصادفی‌سازی کمتر برای ثبات بیشتر
    final speedVariation = 1.0 + (rand.nextDouble() * 0.3 - 0.1) * randomFactor;
    final finalSpeed = targetSpeed * speedVariation;

    // تنظیم سرعت و جهت نهایی
    aiBall.velocity = finalDirection..scale(finalSpeed);

    // شروع حرکت توپ AI
    aiBall.startMoving();

    // ذخیره اطلاعات برای دور بعدی
    _lastAIBehavior = currentBehavior;
    _lastAIDirection = finalDirection.clone();
    _lastAISpeed = finalSpeed;
  }

// متد کمکی برای پیش‌بینی پیشرفته موقعیت بازیکن
  Vector2 _predictPlayerPosition(Ball playerBall, double time) {
    // کپی موقعیت و سرعت فعلی
    Vector2 predictedPosition = playerBall.position.clone();
    Vector2 predictedVelocity = playerBall.velocity.clone();

    // شبیه‌سازی ساده حرکت با برخورد به دیوارها
    double remainingTime = time;
    final dt = 0.1; // گام زمانی کوچک برای شبیه‌سازی

    while (remainingTime > 0) {
      final step = math.min(dt, remainingTime);

      // محاسبه موقعیت بعدی
      final nextPosition = predictedPosition + predictedVelocity * step;

      // بررسی برخورد با دیوارها
      bool collision = false;

      if (nextPosition.x - playerBall.width / 2 <= 0) {
        predictedVelocity.x = predictedVelocity.x.abs();
        collision = true;
      } else if (nextPosition.x + playerBall.width / 2 >= gameWidth) {
        predictedVelocity.x = -predictedVelocity.x.abs();
        collision = true;
      }

      if (nextPosition.y - playerBall.height / 2 <= 0) {
        predictedVelocity.y = predictedVelocity.y.abs();
        collision = true;
      } else if (nextPosition.y + playerBall.height / 2 >= gameHeight) {
        predictedVelocity.y = -predictedVelocity.y.abs();
        collision = true;
      }

      // اگر برخورد نداشت، موقعیت را به‌روز کن
      if (!collision) {
        predictedPosition = nextPosition;
      } else {
        // در صورت برخورد، فقط سرعت را تغییر بده و یک گام کوچک حرکت کن
        predictedPosition += predictedVelocity * (step * 0.1);
      }

      remainingTime -= step;
    }

    return predictedPosition;
  }

  void resetBallPositions() {
    balls[0].position = Vector2(gameWidth * 0.3, gameHeight * 0.3);
    balls[1].position = Vector2(gameWidth * 0.7, gameHeight * 0.7);

    balls[0].velocity = Vector2((rand.nextDouble() - 0.5) * gameWidth, gameHeight * 0.2)
        .normalized()
      ..scale(gameHeight / 4);
    balls[1].velocity = Vector2((rand.nextDouble() - 0.5) * gameWidth, gameHeight * 0.2)
        .normalized()
      ..scale(gameHeight / 4);
  }

  void updateTurnIndicator() {
    final playerText = currentTurn == PlayerTurn.player1 ? 'Your Turn' : 'Enemy\'s Turn';
    final playerColor = currentTurn == PlayerTurn.player1 ? Colors.blue : Colors.red;

    turnIndicator.text = playerText;
    turnIndicator.textRenderer = TextPaint(
      style: TextStyle(
        color: playerColor,
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void updateScoreIndicator() {
    scoreIndicator.text = 'You: $player1Score | Enemy: $player2Score';
  }

  void endGame() {
    overlays.clear();

    AudioManager.stopBackgroundMusic(); // قطع موسیقی پس‌زمینه

    if (balls[0].health <= 0) {
      AudioManager.playSound('lose.mp3',0.5);
      overlays.add('player2Won');
    } else if (balls[1].health <= 0) {
      AudioManager.playSound('win.mp3',0.5);
      overlays.add('player1Won');
    } else if (turnCount >= maxTurns) {
      if (player1Score > player2Score) {
        AudioManager.playSound('win.mp3',0.5);
        overlays.add('player1Won');
      } else if (player2Score > player1Score) {
        AudioManager.playSound('lose.mp3',0.5);
        overlays.add('player2Won');
      }
    }

    pauseEngine();
  }

  void startGame() {
    overlays.clear();
    resumeEngine();
    world.removeAll(world.children.query<Ball>());
    player1Score = 0;
    player2Score = 0;
    turnCount = 0;
    currentTurn = PlayerTurn.player1;
    gameStarted = true;
    playState = PlayState.playing;

    AudioManager.playBackgroundMusic(); // پخش موسیقی پس‌زمینه

    final characterSize = Vector2(ballRadius * 6, ballRadius * 6);

    balls = [
      Ball(
        difficultyModifier: 1.03,
        radius: ballRadius * 2,
        position: Vector2(gameWidth * 0.3, gameHeight * 0.3),
        velocity: Vector2((rand.nextDouble() - 0.5) * gameWidth, gameHeight * 0.2)
            .normalized()
          ..scale(gameHeight / 4),
        health: 215,
        imagePath: 'bahador.png',
        characterSize: characterSize,
        columns: 8,
        rows: 4,
        player: PlayerTurn.player1,
      ),
      Ball(
        difficultyModifier: 1.03,
        radius: ballRadius * 2,
        position: Vector2(gameWidth * 0.7, gameHeight * 0.7),
        velocity: Vector2((rand.nextDouble() - 0.5) * gameWidth, gameHeight * 0.2)
            .normalized()
          ..scale(gameHeight / 4),
        health: 215,
        imagePath: 'enemy.png',
        characterSize: characterSize,
        columns: 8,
        rows: 4,
        player: PlayerTurn.player2,
      ),
    ];
    world.add(balls[0]);
    world.add(balls[1]);

    currentBall = currentTurn == PlayerTurn.player1 ? balls[0] : balls[1];

    updateTurnIndicator();
    updateScoreIndicator();
  }

  @override
  void onTap() {
    super.onTap();
    if (playState == PlayState.welcome) {
      startGame();
    } else if (playState == PlayState.gameOver) {
      overlays.clear();
      endGame();
    } else if (playState == PlayState.won) {
      overlays.clear();
      startGame();
    }
  }

  @override
  Color backgroundColor() => const Color(0xfff2e8cf);

  @override
  void update(double dt) {
    super.update(dt);

    if (playState == PlayState.playing && currentBall != null) {
      handleBallCollisions(dt);
    }
  }

  void handleBallCollisions(double dt) {
    if (!gameStarted || balls.length < 2) return;

    final otherBall = currentBall == balls[0] ? balls[1] : balls[0];

    // محاسبه فاصله بین مرکز دو توپ
    final distance = (currentBall!.position - otherBall.position).length;
    final minDistance = currentBall!.width / 2 + otherBall.width / 2;

    if (currentBall!.isMoving && distance <= minDistance) {
      AudioManager.playSound('hit.mp3',0.9);

      Vector2 normal = currentBall!.position - otherBall.position;
      if (normal.length2 < 0.0001) {
        normal = Vector2(1, 0);
      }

      normal.normalize();
      currentBall!.velocity = currentBall!.velocity.reflected(normal);

      final pushDistance = minDistance * 1.2;
      Vector2 pushVector = normal.clone()..scale(pushDistance);
      currentBall!.position = otherBall.position + pushVector;

      if (currentBall!.velocity.length < gameHeight / 8) {
        currentBall!.velocity.scale(gameHeight / 8 / currentBall!.velocity.length);
      }

      otherBall.decreaseHealth(26);
      otherBall.flash();

      if (currentTurn == PlayerTurn.player1) {
        player1Score += 1;
      } else {
        player2Score += 1;
      }

      updateScoreIndicator();
    }
  }
}