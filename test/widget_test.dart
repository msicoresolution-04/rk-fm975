import 'package:flutter_test/flutter_test.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';

void main() {
  test('App constants are configured', () {
    expect(AppConstants.appName, 'RKFM 97.5 Broadcast');
    expect(AppConstants.countdownDuration, 10);
    expect(AppConstants.defaultPin, '9750');
  });
}
