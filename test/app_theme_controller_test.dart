import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tlaxgomobil/styles/app_colors.dart';
import 'package:tlaxgomobil/styles/app_theme.dart';
import 'package:tlaxgomobil/styles/app_theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final controller = AppThemeController.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await controller.load();
  });

  test('uses the original palette and light appearance by default', () {
    expect(controller.palette.id, 'original');
    expect(controller.palette.primary, const Color(0xFF071126));
    expect(controller.palette.navy, const Color(0xFF060B1D));
    expect(controller.palette.accent, const Color(0xFF12BDF2));
    expect(controller.palette.accentLight, const Color(0xFF29C6F6));
    expect(controller.palette.accentDark, const Color(0xFF078EB9));
    expect(controller.isLightMode, isTrue);
    expect(AppColors.header, const Color(0xFF071126));
    expect(AppColors.headerGlass, const Color(0xEB071126));
    expect(AppColors.background, const Color(0xFFF4F7FB));
    expect(AppColors.glassSurface, const Color(0xDFFFFFFF));
    expect(AppColors.itineraryTop, Colors.white);
    expect(AppColors.itineraryBottom, const Color(0xFFDFF2FA));
    expect(AppTheme.current.brightness, Brightness.light);
  });

  test('persists light mode preference while keeping Tlax.Go colors', () async {
    await controller.setLightMode(false);
    await controller.setLightMode(true);
    expect(AppColors.header, const Color(0xFF071126));
    expect(AppColors.headerGlass, const Color(0xEB071126));
    expect(AppColors.background, const Color(0xFFF4F7FB));
    expect(AppColors.glassSurface, const Color(0xDFFFFFFF));
    expect(AppColors.itineraryTop, Colors.white);
    expect(AppColors.itineraryBottom, const Color(0xFFDFF2FA));
    expect(AppTheme.current.brightness, Brightness.light);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('light_mode_enabled'), isTrue);

    SharedPreferences.setMockInitialValues({'light_mode_enabled': true});
    await controller.load();

    expect(controller.palette.id, 'original');
    expect(controller.isLightMode, isTrue);
  });

  test('allows switching back to dark mode', () async {
    await controller.setLightMode(false);

    expect(controller.isLightMode, isFalse);
    expect(AppColors.background, const Color(0xFF12161C));
    expect(AppTheme.current.brightness, Brightness.dark);
  });
}
