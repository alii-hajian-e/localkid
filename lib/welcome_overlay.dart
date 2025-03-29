import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'audio_manager.dart';
import 'brick_breaker.dart';
import 'enums.dart';

class WelcomeOverlay extends StatefulWidget {
  final BrickBreaker game;
  const WelcomeOverlay(this.game, {super.key});

  @override
  State<WelcomeOverlay> createState() => _WelcomeOverlayState();
}
class _WelcomeOverlayState extends State<WelcomeOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BATTLE GAME',
              style: GoogleFonts.pressStart2p(
                fontSize: 40,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.blue,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
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
                  child: Text('TAP TO START',style: TextStyle(color: Colors.white,fontSize: 24),),
                ),
              ),
              onTap: () {
                widget.game.startGame();
              },
            ),
            const SizedBox(height: 30),
            Container(
              width: gameWidth * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    'HOW TO PLAY:',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 18,
                      color: Colors.yellow,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '- Tap to launch your character\n'
                        '- Use arrow keys to aim\n'
                        '- Hit your opponent to deal damage\n'
                        '- First to reduce opponent\'s health to 0 wins\n'
                        '- Game ends after 10 turns',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                AudioManager.toggleSound();
                setState(() {}); // به‌روزرسانی UI
              },
              icon: Icon(
                AudioManager.isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                color: Colors.white,
              ),
              label: Text(
                AudioManager.isSoundEnabled ? 'Sound: ON' : 'Sound: OFF',
                style: GoogleFonts.pressStart2p(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
