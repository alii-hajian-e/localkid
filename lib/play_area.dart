// import 'dart:async';
// import 'package:flame/collisions.dart';
// import 'package:flame/components.dart';
// import 'package:flutter/material.dart';
// import 'brick_breaker.dart';
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

import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'brick_breaker.dart';

class PlayArea extends RectangleComponent with HasGameReference<BrickBreaker> {
  late RectangleComponent leftWall;
  late RectangleComponent rightWall;

  PlayArea()
      : super(
    paint: Paint()..color = const Color(0xff4b4b50),
  );

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    size = Vector2(game.size.x, game.size.y);

    // دیوار سمت چپ با ظاهر خانه
    leftWall = RectangleComponent(
      position: Vector2(0, 0),
      size: Vector2(100, size.y),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xFFEBE5C2), // رنگ قهوه‌ای
      children: [
        RectangleHitbox(),
        SpriteComponent(
          sprite: await Sprite.load('left_houses.jpeg'),
          position: Vector2(0, size.y * 0.001),
          size: Vector2(100, 400),
        ),
        SpriteComponent(
          sprite: await Sprite.load('grass.jpg'),
          position: Vector2(0, size.y * 0.24),
          size: Vector2(100, 400),
        ),
        SpriteComponent(
          sprite: await Sprite.load('left_houses.jpeg'),
          position: Vector2(0, size.y * 0.4),
          size: Vector2(100, 400),
        ),
        SpriteComponent(
          sprite: await Sprite.load('grass.jpg'),
          position: Vector2(0, size.y * 0.6),
          size: Vector2(100, 400),
        ),
        SpriteComponent(
          sprite: await Sprite.load('left_houses.jpeg'),
          position: Vector2(0, size.y * 0.8),
          size: Vector2(100, 400),
        ),
      ],
    );
    add(leftWall);

    // دیوار سمت راست با ظاهر خانه
    rightWall = RectangleComponent(
      position: Vector2(size.x , 0),
      size: Vector2(100, size.y),
      anchor: Anchor.topRight,
      paint: Paint()..color = const Color(0xFFEBE5C2), // رنگ قهوه‌ای
      children: [
        RectangleHitbox(),
        SpriteComponent(
          sprite: await Sprite.load('right_houses.jpeg'),
          position: Vector2(0, size.y * 0.001),
          size: Vector2(100, 300),
        ),
        SpriteComponent(
          sprite: await Sprite.load('grass.jpg'),
          position: Vector2(0, size.y * 0.13),
          size: Vector2(100, 400),
        ),
        SpriteComponent(
          sprite: await Sprite.load('right_houses.jpeg'),
          position: Vector2(0, size.y * 0.34),
          size: Vector2(100, 300),
        ),
        SpriteComponent(
          sprite: await Sprite.load('right_houses.jpeg'),
          position: Vector2(0, size.y * 0.84),
          size: Vector2(100, 300),
        ),
      ],
    );
    add(rightWall);

    // خطوط خیابان مرکزی
    final streetPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    add(PolygonComponent(
      [
        Vector2(size.x / 2 - 25, 0),
        Vector2(size.x / 2 + 25, 0),
        Vector2(size.x / 2 + 25, size.y),
        Vector2(size.x / 2 - 25, size.y),
      ],
      paint: streetPaint,
    ));
  }
}