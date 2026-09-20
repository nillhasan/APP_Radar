// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
import 'dart:html' as html;

Future<bool> promptPwaInstallImpl() async {
  try {
    if (js.context.hasProperty('triggerPWAInstall')) {
      final res = await js.context.callMethod('triggerPWAInstall');
      return res == true;
    }
  } catch (_) {}
  return false;
}

bool isPwaInstalledImpl() {
  try {
    if (js.context.hasProperty('isPWAInstalled')) {
      final val = js.context['isPWAInstalled'];
      if (val == true) return true;
    }
    return html.window.matchMedia('(display-mode: standalone)').matches;
  } catch (_) {
    return false;
  }
}
