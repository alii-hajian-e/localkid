import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static bool isSoundEnabled = true;

  static Future<void> preloadAll() async {
    await FlameAudio.audioCache.loadAll([
      'launch.mp3',
      'win.mp3',
      'lose.mp3',
      'hit.mp3',
    ]);
  }

  static void playSound(String sound, double volume) {
    if (isSoundEnabled) {
      FlameAudio.play(sound, volume: volume);
    }
  }

  static void toggleSound() {
    isSoundEnabled = !isSoundEnabled;
    if (!isSoundEnabled) {
      stopAllSounds();
    }
  }

  static void stopAllSounds() {
    FlameAudio.bgm.stop();
    FlameAudio.audioCache.clearAll();
  }

  static void playBackgroundMusic() {
    if (isSoundEnabled) {
      FlameAudio.bgm.play('background_music.mp3', volume: 0.2);
    }
  }

  static void stopBackgroundMusic() {
    FlameAudio.bgm.stop();
  }
}