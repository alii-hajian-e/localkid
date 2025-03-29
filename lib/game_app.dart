import 'dart:async';
import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:gamemvp/brick_breaker.dart';
import 'package:gamemvp/play_area.dart';
import 'package:gamemvp/player_won.dart';
import 'package:gamemvp/welcome_overlay.dart';
import 'package:google_fonts/google_fonts.dart';

import 'audio_manager.dart';
import 'ball.dart';
import 'enums.dart';
import 'game_over.dart';
import 'win.dart';


class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.pressStart2pTextTheme().apply(
          bodyColor: const Color(0xff184e77),
          displayColor: const Color(0xff184e77),
        ),
      ),
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xffa9d6e5),
                Color(0xfff2e8cf),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Center(
                child: FittedBox(
                  child: SizedBox(
                    width: gameWidth,
                    height: gameHeight,
                    child: GameWidget.controlled(
                      gameFactory: BrickBreaker.new,
                      overlayBuilderMap: {
                        PlayState.welcome.name: (context, game) => WelcomeOverlay(game as BrickBreaker),
                        PlayState.gameOver.name: (context, game) => GameOverOverlay(game as BrickBreaker),
                        PlayState.won.name: (context, game) => WinnerOverlay(game as BrickBreaker),
                        'player1Won': (context, game) => PlayerWonOverlay(1, game as BrickBreaker),
                        'player2Won': (context, game) => PlayerWonOverlay(2, game as BrickBreaker),
                        // 'draw': (context, game) => DrawOverlay(game as BrickBreaker),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
