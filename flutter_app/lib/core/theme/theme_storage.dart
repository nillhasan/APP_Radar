import 'theme_storage_stub.dart'
    if (dart.library.html) 'theme_storage_web.dart';

String? getStoredThemeMode() => getStoredThemeModeImpl();

void setStoredThemeMode(String? mode) => setStoredThemeModeImpl(mode);
