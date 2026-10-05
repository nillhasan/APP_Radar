// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? getStoredThemeModeImpl() {
  try {
    return html.window.localStorage['appradar_rekki_theme_mode'];
  } catch (_) {
    return null;
  }
}

void setStoredThemeModeImpl(String? mode) {
  try {
    if (mode == null) {
      html.window.localStorage.remove('appradar_rekki_theme_mode');
    } else {
      html.window.localStorage['appradar_rekki_theme_mode'] = mode;
    }
  } catch (_) {}
}
