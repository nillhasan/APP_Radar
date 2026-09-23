// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
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

Set<String> getStoredUrlTeardownsImpl() {
  try {
    final raw = html.window.localStorage['appradar_url_teardowns'];
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    }
  } catch (_) {}
  return {};
}

void setStoredUrlTeardownsImpl(Set<String> ids) {
  try {
    html.window.localStorage['appradar_url_teardowns'] = jsonEncode(ids.toList());
  } catch (_) {}
}
