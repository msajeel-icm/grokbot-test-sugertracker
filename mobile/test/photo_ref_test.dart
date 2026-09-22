import 'package:flutter_test/flutter_test.dart';
import 'package:sugar_tracker/api/models.dart';

void main() {
  test('confirm stores a device path and drops one that does not fit', () {
    const photo = MealPhoto(bytes: [1], name: 'plate.jpg', path: '/tmp/plate.jpg');
    expect(photoRefForLog(photo), '/tmp/plate.jpg');
    expect(photoRefForLog(const MealPhoto(bytes: [1], name: 'plate.jpg')), isNull);
    expect(
      photoRefForLog(MealPhoto(bytes: const [1], name: 'plate.jpg', path: 'x' * 1025)),
      isNull,
    );
  });
}
