import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_notifications/notifications.dart';

import '../../dependencies.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  ReminderIntensity _intensity = ReminderIntensity.visible;
  var _permissionGranted = true;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final scheduled = ref.watch(reminderSchedulerProvider).scheduled;
    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios suaves')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HabitarSpacing.lg),
          children: [
            const HabitarMoment(
              title: 'Como avisamos sin invadir?',
              body:
                  'Los recordatorios deben ayudar, no perseguir. Elige el tono que cuide mejor el momento.',
              color: HabitarColors.surfaceWarm,
            ),
            const SizedBox(height: HabitarSpacing.md),
            SwitchListTile(
              value: _permissionGranted,
              onChanged: (value) => setState(() => _permissionGranted = value),
              title: const Text('Quiero recibir avisos'),
            ),
            const SizedBox(height: HabitarSpacing.md),
            DropdownButtonFormField<ReminderIntensity>(
              initialValue: _intensity,
              decoration: const InputDecoration(labelText: 'Tono del aviso'),
              items: const [
                DropdownMenuItem(
                    value: ReminderIntensity.quiet, child: Text('Discreta')),
                DropdownMenuItem(
                    value: ReminderIntensity.visible, child: Text('Visible')),
                DropdownMenuItem(
                    value: ReminderIntensity.persistentAllowed,
                    child: Text('Insistente permitida')),
                DropdownMenuItem(
                    value: ReminderIntensity.silent, child: Text('Silenciosa')),
                DropdownMenuItem(
                    value: ReminderIntensity.wearableOnly,
                    child: Text('Solo smartwatch')),
              ],
              onChanged: (value) => setState(
                  () => _intensity = value ?? ReminderIntensity.visible),
            ),
            const SizedBox(height: HabitarSpacing.lg),
            FilledButton(
                onPressed: _saveConsent,
                child: const Text('Guardar este cuidado')),
            const SizedBox(height: HabitarSpacing.sm),
            OutlinedButton(
                onPressed: _scheduleDemo,
                child: const Text('Probar un aviso suave')),
            if (_message != null) ...[
              const SizedBox(height: HabitarSpacing.md),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(HabitarSpacing.md),
                      child: Text(_message!))),
            ],
            const SizedBox(height: HabitarSpacing.lg),
            Text('Avisos preparados',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: HabitarSpacing.md),
            for (final request in scheduled)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(HabitarSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(request.body),
                      Text('Incluye ${request.actions.length} apoyo(s).'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveConsent() async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      setState(() => _message = 'Primero crea un perfil.');
      return;
    }
    await ref.read(notificationServiceProvider).saveConsent(
          profileId: profileId,
          permissionStatus: _permissionGranted
              ? NotificationPermissionStatus.granted
              : NotificationPermissionStatus.denied,
          intensity: _intensity,
        );
    setState(() => _message = 'Listo. Los avisos respetaran este tono.');
  }

  Future<void> _scheduleDemo() async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      setState(() => _message = 'Primero crea un perfil.');
      return;
    }
    final plan =
        await ref.read(notificationServiceProvider).scheduleRoutineStart(
              profileId: profileId,
              routineId: 'demo-routine',
              routineTitle: 'Rutina de salida',
              firstStepTitle: 'Tomar la mochila',
              scheduledAt: DateTime.now().add(const Duration(minutes: 10)),
            );
    setState(() {
      _message =
          plan.isBlocked ? plan.blockedReason : 'Aviso preparado con cuidado.';
    });
  }
}
