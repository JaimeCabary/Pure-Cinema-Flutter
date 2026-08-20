import 'package:flutter/services.dart';

void playCashChimeAudio() {
  try {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  } catch (_) {}
}
