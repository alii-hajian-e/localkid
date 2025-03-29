import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brick_breaker.dart';

class GameOverOverlay extends StatelessWidget {
  final BrickBreaker game;

  const GameOverOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GAME OVER',
              style: GoogleFonts.pressStart2p(
                fontSize: 40,
                color: Colors.red,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.red.shade900,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'FINAL SCORE',
              style: GoogleFonts.pressStart2p(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      'YOU',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${game.player1Score}',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 80),
                Column(
                  children: [
                    Text(
                      'ENEMY',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${game.player2Score}',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 50),
            GestureDetector(
              child: Container(
                width: MediaQuery.of(context).size.width / 1.1,
                height: 80,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    color: Colors.blueGrey
                ),
                child: Center(
                  child: Text('TAP TO PLAY AGAIN',style: TextStyle(color: Colors.white,fontSize: 24),),
                ),
              ),
              onTap: () {
                game.overlays.clear();
                game.startGame();
              },
            ),
          ],
        ),
      ),
    );
  }
}
