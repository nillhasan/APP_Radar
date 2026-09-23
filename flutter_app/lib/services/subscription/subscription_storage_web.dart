// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? getStoredTierImpl() {
  try {
    return html.window.localStorage['appradar_user_tier'];
  } catch (_) {
    return null;
  }
}

void setStoredTierImpl(String? tier) {
  try {
    if (tier == null) {
      html.window.localStorage.remove('appradar_user_tier');
    } else {
      html.window.localStorage['appradar_user_tier'] = tier;
    }
  } catch (_) {}
}
