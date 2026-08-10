import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const runtimeScreens = [
    'lib/src/features/family_dashboard/family_dashboard_screen.dart',
    'lib/src/features/portal/portal_screens.dart',
    'lib/src/features/wearables/wearables_screen.dart',
    'lib/src/features/profile_setup/profile_setup_screen.dart',
  ];

  test('real-session screens do not ship profile or routine demo copy', () {
    final forbidden = [
      'Tomi',
      'Después de la escuela',
      'Despues de la escuela',
      'Preparar la mochila',
      'Hacer la tarea',
      'Prepararse para dormir',
      'Prepararnos para salir',
      'Tiempo libre',
      'Rutina no iniciada',
      'Perfil demo',
    ];

    for (final path in runtimeScreens) {
      final source = _source(path);
      for (final text in forbidden) {
        expect(
          source.contains(text),
          isFalse,
          reason: '$path must not contain "$text" as runtime fallback copy.',
        );
      }
    }
  });

  test('real-session screens do not contain mojibake markers', () {
    final forbidden = ['Ã', 'Â', '�'];

    for (final path in runtimeScreens) {
      final source = _source(path);
      for (final text in forbidden) {
        expect(
          source.contains(text),
          isFalse,
          reason: '$path contains corrupted text marker "$text".',
        );
      }
    }
  });
}

String _source(String packagePath) {
  final packageFile = File(packagePath);
  if (packageFile.existsSync()) {
    return packageFile.readAsStringSync();
  }
  return File('apps/mobile/$packagePath').readAsStringSync();
}
