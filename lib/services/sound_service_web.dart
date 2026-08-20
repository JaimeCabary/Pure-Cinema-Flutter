import 'dart:js_interop';
import 'package:flutter/services.dart';

@JS('eval')
external void _jsEval(String code);

void playCashChimeAudio() {
  try {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  } catch (_) {}

  try {
    const code = '''
      (function() {
        try {
          var AudioCtx = window.AudioContext || window.webkitAudioContext;
          if (!AudioCtx) return;
          var ctx = new AudioCtx();
          if (ctx.state === 'suspended') {
            ctx.resume();
          }
          function playTone(freq, delay, dur, vol) {
            var start = ctx.currentTime + delay;
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(freq, start);
            gain.gain.setValueAtTime(vol, start);
            gain.gain.exponentialRampToValueAtTime(0.0001, start + dur);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(start);
            osc.stop(start + dur);
          }
          // Bright, satisfying dual-bell metallic cash register register chime
          playTone(1046.50, 0.00, 0.40, 0.25); // C6
          playTone(1318.51, 0.08, 0.50, 0.35); // E6
          playTone(1760.00, 0.16, 0.70, 0.45); // A6
          playTone(2093.00, 0.22, 0.85, 0.30); // C7 (sparkle)
        } catch(e) {}
      })();
    ''';
    _jsEval(code);
  } catch (_) {}
}
