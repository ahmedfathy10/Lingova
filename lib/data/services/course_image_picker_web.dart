import 'dart:async';
import 'dart:html';

Future<String?> pickCourseImageDataUrl() {
  final completer = Completer<String?>();
  final input = FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;

  void handleChange(_) {
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      completer.complete(null);
      input.remove();
      return;
    }

    final reader = FileReader();
    bool completed = false;

    reader.onLoad.listen((_) {
      if (!completed) {
        completed = true;
        completer.complete(reader.result?.toString());
        input.remove();
      }
    });

    reader.onError.listen((_) {
      if (!completed) {
        completed = true;
        completer.complete(null);
        input.remove();
      }
    });

    reader.readAsDataUrl(file);
  }

  input.onChange.listen(
    handleChange,
    onError: (_) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      input.remove();
    },
  );

  document.body?.append(input);
  input.click();

  return completer.future;
}
