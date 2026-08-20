import 'sound_service_stub.dart'
    if (dart.library.js_interop) 'sound_service_web.dart' as sound_impl;

class SoundService {
  static void playMoneySuccessSound() {
    sound_impl.playCashChimeAudio();
  }
}
