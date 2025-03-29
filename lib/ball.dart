import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import 'audio_manager.dart';
import 'brick_breaker.dart';
import 'enums.dart';
import 'dart:math' as math;

class Ball extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker>, DragCallbacks {
  Ball({
    required this.velocity,
    required super.position,
    required double radius,
    required this.difficultyModifier,
    required this.health,
    required this.imagePath,
    required this.characterSize,
    required this.columns,
    required this.rows,
    required this.player,
  })  : initialHealth = health,
        super(
        size: characterSize,
        anchor: Anchor.center,
        children: [CircleHitbox(radius: radius)],
      );

  Vector2 velocity;
  final double difficultyModifier;
  bool isMoving = false;
  double moveTime = 0;
  int health;
  final int initialHealth;
  final String imagePath;
  final Vector2 characterSize;
  final int columns;
  final int rows;
  final PlayerTurn player;
  Direction direction = Direction.down;
  late SpriteSheet spriteSheet;

  final Paint _healthBarBgPaint = Paint()..color = Colors.grey.shade800;
  final Paint _healthBarFgPaint = Paint()..color = Colors.green;
  final double _healthBarHeight = 10.0;
  final double _healthBarWidth = 100.0;

  bool isFlashing = false;
  double flashTime = 0.0;
  final double flashDuration = 0.2;

  Vector2? dragStartPosition;
  Vector2? dragEndPosition;
  bool isDragging = false;

  // اضافه کردن PositionComponent برای نمایش فلش
  late SpriteComponent arrowComponent;
  bool isArrowVisible = false; // مدیریت visibility به صورت دستی

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      spriteSheet = SpriteSheet(
        image: await game.images.load(imagePath),
        srcSize: Vector2(
          (await game.images.load(imagePath)).width / columns.toDouble(),
          (await game.images.load(imagePath)).height / rows.toDouble(),
        ),
      );

      animation = spriteSheet.createAnimation(row: 0, stepTime: 0.2);
    } catch (e) {
      debugPrint('Error loading sprite sheet: $e');
      final circleRenderComponent = CircleComponent(
        radius: width / 2,
        paint: Paint()..color = player == PlayerTurn.player1 ? Colors.blue : Colors.red,
      );
      add(circleRenderComponent);
    }

    // بارگذاری تصویر فلش و تنظیم PositionComponent
    final arrowSprite = await Sprite.load('arrow.png');
    arrowComponent = SpriteComponent()
      ..sprite = arrowSprite
      ..size = Vector2(120, 64) // اندازه فلش
      ..anchor = Anchor.center
      ..position = position
      ..angle = 0; // زاویه اولیه
    add(arrowComponent);

    // در ابتدا فلش مخفی است
    arrowComponent.opacity = 0;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (player == PlayerTurn.player1 && !isMoving) {
      dragStartPosition = event.localPosition;
      isDragging = true;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isDragging) {
      dragEndPosition = event.localPosition;

      // محاسبه جهت و زاویه فلش
      final direction = dragEndPosition! - dragStartPosition!;
      final reversedDirection = -direction; // معکوس کردن جهت

      // محاسبه زاویه در محدوده 0 تا 360 درجه
      double angle = math.atan2(reversedDirection.y, reversedDirection.x);
      // تبدیل به محدوده 0 تا 2π
      if (angle < 0) {
        angle += 2 * math.pi;
      }

      // تنظیم موقعیت فلش کمی جلوتر از dragStartPosition
      final arrowOffset = reversedDirection.normalized() * 100; // 100 پیکسل جلوتر
      arrowComponent.position = dragStartPosition! + arrowOffset;

      // تنظیم زاویه فلش
      arrowComponent.angle = angle;
      arrowComponent.opacity = 1; // نمایش فلش
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (isDragging) {
      isDragging = false;
      arrowComponent.opacity = 0; // مخفی کردن فلش پس از رها کردن

      if (dragStartPosition != null && dragEndPosition != null) {
        final direction = dragStartPosition! - dragEndPosition!;
        velocity = direction.normalized() * gameHeight / 4;
        startMoving();
      }
      dragStartPosition = null;
      dragEndPosition = null;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // پس‌زمینه نوار سلامت
    final healthBarBgRect = Rect.fromLTWH(
      -_healthBarWidth / 2,
      -height / 2,
      _healthBarWidth,
      _healthBarHeight + 10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(healthBarBgRect, Radius.circular(10)),
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    // نوار سلامت اصلی
    final healthPercentage = health / initialHealth;
    final healthBarFgRect = Rect.fromLTWH(
      -_healthBarWidth / 2,
      -height / 2,
      _healthBarWidth * healthPercentage,
      _healthBarHeight ,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(healthBarFgRect, Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            healthPercentage > 0.6 ? Color(0xFF00FF00) : Colors.green,
            healthPercentage > 0.3 ? Color(0xFFFFA500) : Colors.orange,
            Color(0xFFFF0000),
          ],
        ).createShader(healthBarFgRect),
    );

    // متن امتیاز با جلوه سایه
    final scoreText = TextPainter(
      text: TextSpan(
        text: '$health',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
          Shadow(
          color: Colors.black,
          blurRadius: 5,
          offset: Offset(2, 2),)
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    scoreText.layout();
    scoreText.paint(
      canvas,
      Offset(-scoreText.width / 2, height / 2 - 155),
    );

    // نام بازیکن با انیمیشن
    final playerText = player == PlayerTurn.player1 ? "You" : "Enemy";
    final playerTextPainter = TextPainter(
      text: TextSpan(
        text: playerText,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: player == PlayerTurn.player1
              ? Colors.blue.shade300
              : Colors.red.shade300,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 8,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    playerTextPainter.layout();
    playerTextPainter.paint(
      canvas,
      Offset(-playerTextPainter.width / 2, height - 200),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isFlashing) {
      flashTime -= dt;
      if (flashTime <= 0) {
        isFlashing = false;
        paint = Paint()..color = Colors.white;
        opacity = 1.0;
      }
    }

    if (isMoving) {

      // به‌روزرسانی جهت حرکت
      if (velocity.x.abs() > velocity.y.abs()) {
        direction = velocity.x > 0 ? Direction.right : Direction.left;
      } else {
        direction = velocity.y > 0 ? Direction.down : Direction.up;
      }

      // به‌روزرسانی انیمیشن
      updateAnimation();

      // به‌روزرسانی موقعیت کاراکتر بر اساس سرعت
      if (velocity.length2 > 0) {
        position += velocity * dt;
      }

      // کاهش زمان حرکت
      moveTime -= dt;

      // اگر زمان حرکت به پایان رسید، حرکت متوقف شود
      if (moveTime <= 0) {
        isMoving = false;
        game.switchTurn(); // تغییر نوبت به بازیکن بعدی
      }

      // برخورد با دیوارها
      if (position.x - width / 2 <= 100) {
        position.x = 100 + width / 2;
        velocity.x = -velocity.x * 0.9; // کاهش سرعت پس از برخورد
        AudioManager.playSound('wall_hit.mp3', 0.5);
      }
      // برخورد با دیوار راست (خانه سمت راست)
      else if (position.x + width / 2 >= game.size.x - 100) {
        position.x = game.size.x - 100 - width / 2;
        velocity.x = -velocity.x * 0.9; // کاهش سرعت پس از برخورد
        AudioManager.playSound('wall_hit.mp3', 0.5);
      }

      // برخورد با دیوارهای بالا و پایین
      if (position.y - height / 2 <= 0) {
        position.y = height / 2;
        velocity.y = -velocity.y;
        AudioManager.playSound('wall_hit.mp3', 0.5);
      }
      else if (position.y + height / 2 >= game.size.y) {
        position.y = game.size.y - height / 2;
        velocity.y = -velocity.y;
        AudioManager.playSound('wall_hit.mp3', 0.5);
      }
    }
  }

  void updateAnimation() {
    int row = 0;
    switch (direction) {
      case Direction.down:
        row = 0;
        break;
      case Direction.up:
        row = 1;
        break;
      case Direction.left:
        row = 2;
        break;
      case Direction.right:
        row = 3;
        break;
    }
    animation = spriteSheet.createAnimation(row: row, stepTime: 0.1);

  }

  void startMoving() {
    isMoving = true; // فعال کردن حرکت
    moveTime = 5; // زمان حرکت

    if (velocity.length2 < 0.1) {
      // اگر سرعت خیلی کم است، یک سرعت پیش‌فرض تنظیم کنید
      velocity = Vector2(
        (game.rand.nextDouble() - 0.5) * gameWidth,
        (game.rand.nextDouble() - 0.5) * gameHeight,
      ).normalized()..scale(gameHeight / 4);
    }

    // اضافه کردن یک افکت برای نشان دادن شروع حرکت
    add(
      ScaleEffect.by(
        Vector2.all(1.2),
        EffectController(duration: 0.2, reverseDuration: 0.2),
      ),
    );
  }

  void decreaseHealth(int damage) {
    health -= damage;
    if (health < 0) health = 0;
    add(
      MoveByEffect(
        Vector2(10, 0),
        EffectController(duration: 0.1, reverseDuration: 0.1),
      ),
    );

    // add(
    //   ParticleSystemComponent(
    //     particle: Particle.generate(
    //       count: 40,
    //       generator: (i) => AcceleratedParticle(
    //         acceleration: Vector2(600, 600),
    //         speed: Vector2.random() * 100,
    //         position: position.clone(),
    //         child: CircleParticle(
    //           radius: 2,
    //           paint: Paint()..color = Colors.red,
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }

  void flash() {
    isFlashing = true;
    flashTime = flashDuration;

    AudioManager.playSound('hit.mp3',0.9);

    paint = Paint()..color = Colors.white;
    opacity = 0.8;

    add(
      ScaleEffect.by(
        Vector2.all(1.3),
        EffectController(duration: 0.1, reverseDuration: 0.1),
      ),
    );
  }
}