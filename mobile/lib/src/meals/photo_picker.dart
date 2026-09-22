import 'package:image_picker/image_picker.dart';

import '../api/models.dart';

/// Opens the gallery and returns the chosen photo, or null if the user backs out.
Future<MealPhoto?> pickMealPhoto() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    imageQuality: 85,
    requestFullMetadata: false,
  );
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  final name = picked.name.trim().isEmpty ? 'meal.jpg' : picked.name.trim();
  return MealPhoto(bytes: bytes, filename: name, path: picked.path);
}
