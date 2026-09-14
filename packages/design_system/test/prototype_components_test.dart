// Widget coverage for the 4 reusable components introduced in bloque 3 of
// etapa 1 del rediseño (docs/prototipo-habitar.md, sección "Componentes
// reutilizables"): SegmentedBar, EstadoPill, HabitarToggle, IconoRutina.
// Every component is also rendered at 320px width, the narrowest target
// per the redesign brief.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_design_system/design_system.dart';

Future<void> _pumpAt320(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(320, 200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: buildHabitarTheme(),
    home: Scaffold(body: Center(child: child)),
  ));
}

void main() {
  group('SegmentedBar', () {
    testWidgets('renders total segments and colors the completed ones',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildHabitarTheme(),
        home: const Scaffold(
          body: SegmentedBar(total: 5, done: 2),
        ),
      ));

      final containers = tester
          .widgetList<Container>(find.descendant(
            of: find.byType(SegmentedBar),
            matching: find.byType(Container),
          ))
          .toList();
      expect(containers, hasLength(5));
      Color colorOf(Container c) => (c.decoration as BoxDecoration).color!;
      expect(colorOf(containers[0]), HabitarColors.green);
      expect(colorOf(containers[1]), HabitarColors.green);
      expect(colorOf(containers[2]), HabitarColors.greenMedium);
      expect(colorOf(containers[3]), HabitarColors.greenMedium);
      expect(colorOf(containers[4]), HabitarColors.greenMedium);
      expect(tester.takeException(), isNull);
    });

    testWidgets('never shows numbers or percentages', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildHabitarTheme(),
        home: const Scaffold(
          body: SegmentedBar(total: 4, done: 3),
        ),
      ));

      expect(find.byType(Text), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('clamps done above total instead of overflowing',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildHabitarTheme(),
        home: const Scaffold(
          body: SegmentedBar(total: 3, done: 99),
        ),
      ));

      final containers = tester
          .widgetList<Container>(find.descendant(
            of: find.byType(SegmentedBar),
            matching: find.byType(Container),
          ))
          .toList();
      expect(containers, hasLength(3));
      for (final c in containers) {
        expect((c.decoration as BoxDecoration).color, HabitarColors.green);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('total 0 does not throw', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SegmentedBar(total: 0, done: 0)),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at 320px with the child height (6px)', (tester) async {
      await _pumpAt320(
        tester,
        const SizedBox(
          width: 280,
          child: SegmentedBar(total: 6, done: 4, height: 6),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('EstadoPill', () {
    testWidgets('Completada: fondo greenLight, texto green', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EstadoPill(estado: EstadoRutina.completada)),
      ));
      expect(find.text('Completada'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      expect((container.decoration as BoxDecoration).color,
          HabitarColors.greenLight);
      final text = tester.widget<Text>(find.text('Completada'));
      expect(text.style?.color, HabitarColors.green);
    });

    testWidgets('En curso: fondo green, texto white', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EstadoPill(estado: EstadoRutina.enCurso)),
      ));
      expect(find.text('En curso'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      expect(
          (container.decoration as BoxDecoration).color, HabitarColors.green);
      final text = tester.widget<Text>(find.text('En curso'));
      expect(text.style?.color, HabitarColors.white);
    });

    testWidgets('Programada: fondo #EFEFEF, texto gray', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EstadoPill(estado: EstadoRutina.programada)),
      ));
      expect(find.text('Programada'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      expect((container.decoration as BoxDecoration).color,
          const Color(0xFFEFEFEF));
      final text = tester.widget<Text>(find.text('Programada'));
      expect(text.style?.color, HabitarColors.gray);
    });

    testWidgets('fits at 320px next to a long routine name', (tester) async {
      await _pumpAt320(
        tester,
        const SizedBox(
          width: 300,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Rutina de preparación para salir a la escuela',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              EstadoPill(estado: EstadoRutina.enCurso),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('HabitarToggle', () {
    testWidgets('renders on and off with the right track color',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HabitarToggle(value: true)),
      ));
      var container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer));
      expect(
          (container.decoration as BoxDecoration).color, HabitarColors.green);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HabitarToggle(value: false)),
      ));
      container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer));
      expect((container.decoration as BoxDecoration).color,
          const Color(0xFFD1D1D1));
    });

    testWidgets('tapping calls onChanged with the flipped value',
        (tester) async {
      bool? newValue;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HabitarToggle(
            value: false,
            onChanged: (v) => newValue = v,
          ),
        ),
      ));

      await tester.tap(find.byType(HabitarToggle));
      await tester.pump();

      expect(newValue, isTrue);
    });

    testWidgets('without onChanged, tapping does nothing', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HabitarToggle(value: false)),
      ));

      await tester.tap(find.byType(HabitarToggle));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('is exactly 44x24px (spec size)', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HabitarToggle(value: true)),
      ));
      final size = tester.getSize(find.byType(HabitarToggle));
      expect(size.width, 44);
      expect(size.height, 24);
    });

    testWidgets('fits at 320px inside a settings row', (tester) async {
      await _pumpAt320(
        tester,
        const SizedBox(
          width: 280,
          // HabitarToggle es de ancho fijo (44px) - cualquier label al
          // lado tiene que ir en Expanded/Flexible, igual que cualquier
          // otra fila con un elemento de ancho fijo. Sin el Expanded acá,
          // este mismo layout desborda a 320px con un label realista
          // ("Permitir pedir ayuda", como en Editar rutina) - hallazgo
          // real de este test, no un defecto del propio HabitarToggle.
          child: Row(
            children: [
              Expanded(child: Text('Permitir pedir ayuda')),
              HabitarToggle(value: true),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('IconoRutina', () {
    testWidgets('mañana: fondo amberLight, ícono amberLightText',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: IconoRutina(momento: MomentoRutina.manana)),
      ));
      final container = tester.widget<Container>(find.byType(Container));
      expect((container.decoration as BoxDecoration).color,
          HabitarColors.amberLight);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.wb_sunny_rounded);
      expect(icon.color, HabitarColors.amberLightText);
    });

    testWidgets('tarde: fondo amber, ícono amberText', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: IconoRutina(momento: MomentoRutina.tarde)),
      ));
      final container = tester.widget<Container>(find.byType(Container));
      expect(
          (container.decoration as BoxDecoration).color, HabitarColors.amber);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.backpack_rounded);
      expect(icon.color, HabitarColors.amberText);
    });

    testWidgets('noche: fondo violet, ícono violetText', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: IconoRutina(momento: MomentoRutina.noche)),
      ));
      final container = tester.widget<Container>(find.byType(Container));
      expect((container.decoration as BoxDecoration).color,
          HabitarColors.violet);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.nightlight_round);
      expect(icon.color, HabitarColors.violetText);
    });

    testWidgets('default size is within the 38-40px spec range',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: IconoRutina(momento: MomentoRutina.manana)),
      ));
      final size = tester.getSize(find.byType(IconoRutina));
      expect(size.width, greaterThanOrEqualTo(38));
      expect(size.width, lessThanOrEqualTo(40));
      expect(size.height, size.width);
    });

    testWidgets('fits at 320px in a routine list row', (tester) async {
      await _pumpAt320(
        tester,
        const SizedBox(
          width: 300,
          child: Row(
            children: [
              IconoRutina(momento: MomentoRutina.tarde),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Rutina de la tarde después de la escuela',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              EstadoPill(estado: EstadoRutina.programada),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
