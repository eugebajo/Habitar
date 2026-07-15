import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';

import '../../dependencies.dart';

class WellbeingCheckInScreen extends ConsumerStatefulWidget {
  const WellbeingCheckInScreen({super.key});

  @override
  ConsumerState<WellbeingCheckInScreen> createState() =>
      _WellbeingCheckInScreenState();
}

class _WellbeingCheckInScreenState
    extends ConsumerState<WellbeingCheckInScreen> {
  String _emotion = 'tranquilo';
  double _energy = 3;
  double _overload = 1;
  var _needsQuiet = false;
  var _needsMovement = false;
  var _skipped = false;
  List<SupportAction> _actions = [];
  String? _message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Como estoy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HabitarSpacing.lg),
          children: [
            Text('Check-in opcional',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: HabitarSpacing.md),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'tranquilo', label: Text('Tranquilo')),
                ButtonSegment(value: 'cansado', label: Text('Cansado')),
                ButtonSegment(value: 'frustrado', label: Text('Frustrado')),
              ],
              selected: {_emotion},
              onSelectionChanged: _skipped
                  ? null
                  : (selection) => setState(() => _emotion = selection.first),
            ),
            const SizedBox(height: HabitarSpacing.md),
            _SliderTile(
                label: 'Energia',
                value: _energy,
                onChanged: _skipped
                    ? null
                    : (value) => setState(() => _energy = value)),
            _SliderTile(
                label: 'Sobrecarga',
                value: _overload,
                onChanged: _skipped
                    ? null
                    : (value) => setState(() => _overload = value)),
            SwitchListTile(
              value: _needsQuiet,
              onChanged: _skipped
                  ? null
                  : (value) => setState(() => _needsQuiet = value),
              title: const Text('Necesito silencio'),
            ),
            SwitchListTile(
              value: _needsMovement,
              onChanged: _skipped
                  ? null
                  : (value) => setState(() => _needsMovement = value),
              title: const Text('Necesito moverme'),
            ),
            CheckboxListTile(
              value: _skipped,
              onChanged: (value) => setState(() => _skipped = value ?? false),
              title: const Text('No quiero responder ahora'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: HabitarSpacing.md),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
            if (_message != null) ...[
              const SizedBox(height: HabitarSpacing.md),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(HabitarSpacing.md),
                      child: Text(_message!))),
            ],
            const SizedBox(height: HabitarSpacing.lg),
            Text('Apoyos sugeridos',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: HabitarSpacing.md),
            for (final action in _actions)
              Card(
                child: ListTile(
                  title: Text(action.label),
                  trailing: OutlinedButton(
                      onPressed: () => _requestSupport(action),
                      child: const Text('Usar')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      setState(() => _message = 'Primero crea un perfil.');
      return;
    }
    final input = EmotionCheckInInput(
      profileId: profileId,
      emotion: _emotion,
      energyLevel: _energy.round(),
      overloadLevel: _overload.round(),
      needsQuiet: _needsQuiet,
      needsMovement: _needsMovement,
      skipped: _skipped,
    );
    await ref.read(wellbeingServiceProvider).recordCheckIn(input);
    setState(() {
      _actions = ref.read(wellbeingServiceProvider).supportActionsFor(input);
      _message = _skipped
          ? 'Podemos responder despues.'
          : 'Registro guardado sin interpretacion clinica.';
    });
  }

  Future<void> _requestSupport(SupportAction action) async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      return;
    }
    await ref
        .read(wellbeingServiceProvider)
        .requestSupport(profileId: profileId, action: action);
    setState(() => _message = 'Apoyo registrado: ${action.label}.');
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile(
      {required this.label, required this.value, required this.onChanged});

  final String label;
  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()}'),
        Slider(
            value: value, min: 0, max: 5, divisions: 5, onChanged: onChanged),
      ],
    );
  }
}
