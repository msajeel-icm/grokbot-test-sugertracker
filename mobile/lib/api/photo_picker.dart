import 'package:image_picker/image_picker.dart';

import 'models.dart';
import 'sugar_api.dart';

Future<MealPhoto?> pickMealPhoto() async {
  try {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    return MealPhoto(bytes: bytes, name: file.name, path: file.path);
  } catch (_) {
    throw ApiException('Photo library is unavailable. Enter a hint instead.');
  }
}
