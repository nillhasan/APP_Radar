import 'package:flutter/foundation.dart';
import 'pwa_service_stub.dart'
    if (dart.library.html) 'pwa_service_web.dart';

class PwaService {
  static bool get isWeb => kIsWeb;

  static bool isPwaInstalled() {
    if (!kIsWeb) return false;
    return isPwaInstalledImpl();
  }

  static Future<bool> promptInstall() async {
    if (!kIsWeb) return false;
    return await promptPwaInstallImpl();
  }
}
