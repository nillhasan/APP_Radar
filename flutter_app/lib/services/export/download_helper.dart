import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';

void downloadFile({
  required String fileName,
  required String content,
  required String mimeType,
}) {
  downloadFileImpl(
    fileName: fileName,
    content: content,
    mimeType: mimeType,
  );
}
