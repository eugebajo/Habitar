// Etapa 3 (notificaciones push). Preferencias de aviso POR ADULTO -
// interruptor de "Recibir avisos" y horario silencioso opcional. Vive
// dentro de Cuenta, no como una sección nueva de Ajustes: estas
// preferencias son de la CUENTA del adulto (notification_preferences_by_user,
// ver supabase/migrations/0015_device_tokens.sql), el mismo eje que el
// resto de lo que ya vive en Cuenta (transferir rol, eliminar cuenta) - no
// el de Ajustes/Recordatorios suaves (notification_settings_screen.dart),
// que es la intensidad de aviso LOCAL de un PERFIL DE CHICO. Mezclar las
// dos en una sola pantalla habría confundido justo la distinción que
// motivó tener dos tablas separadas en la migración.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';

import '../../dependencies.dart';

class PushNotificationSettingsScreen extends ConsumerStatefulWidget {
  const PushNotificationSettingsScreen({super.key});

  @override
  ConsumerState<PushNotificationSettingsScreen> createState() =>
      _PushNotificationSettingsScreenState();
}

class _PushNotificationSettingsScreenState
    extends ConsumerState<PushNotificationSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _pushEnabled = true;
  TimeOfDay? _quietStart;
  TimeOfDay? _quietEnd;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await ref.read(authRepositoryProvider).currentUser();
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final preference = await ref
        .read(pushNotificationPreferenceRepositoryProvider)
        .forUser(user.metadata.id);
    if (!mounted) return;
    setState(() {
      _userId = user.metadata.id;
      // Sin fila todavía (nadie tocó esto nunca): mismo default que del
      // lado del servidor, push habilitado y sin horario silencioso - ver
      // la nota de default en resolve_routine_notification_recipients.
      _pushEnabled = preference?.pushEnabled ?? true;
      _quietStart = _timeOfDayFrom(
        preference?.quietHoursStartHour,
        preference?.quietHoursStartMinute,
      );
      _quietEnd = _timeOfDayFrom(
        preference?.quietHoursEndHour,
        preference?.quietHoursEndMinute,
      );
      _loading = false;
    });
  }

  TimeOfDay? _timeOfDayFrom(int? hour, int? minute) =>
      hour == null || minute == null
          ? null
          : TimeOfDay(hour: hour, minute: minute);

  Future<void> _pickTime({required bool isStart}) async {
    final initial = (isStart ? _quietStart : _quietEnd) ??
        const TimeOfDay(hour: 21, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _quietStart = picked;
      } else {
        _quietEnd = picked;
      }
    });
  }

  void _clearQuietHours() {
    setState(() {
      _quietStart = null;
      _quietEnd = null;
    });
  }

  Future<void> _save() async {
    final userId = _userId;
    if (userId == null) return;
    // Los dos límites van juntos o ninguno - mismo check constraint que
    // notification_preferences_quiet_hours_pair en la migración. Si falta
    // uno solo, no se manda a guardar: se le pide al adulto que complete
    // el otro o borre el que puso.
    if ((_quietStart == null) != (_quietEnd == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Elegí las dos horas del horario silencioso, o ninguna.',
        ),
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(pushNotificationPreferenceRepositoryProvider).save(
            PushNotificationPreference(
              userId: userId,
              pushEnabled: _pushEnabled,
              quietHoursStartHour: _quietStart?.hour,
              quietHoursStartMinute: _quietStart?.minute,
              quietHoursEndHour: _quietEnd?.hour,
              quietHoursEndMinute: _quietEnd?.minute,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferencias guardadas')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(HabitarSpacing.lg),
                children: [
                  Text(
                    'Avisos entre adultos',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: HabitarSpacing.sm),
                  Text(
                    'Cuando otro adulto de tu familia complete una rutina, '
                    'te avisamos acá - sin que tengas que abrir Habitar.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: HabitarSpacing.xl),
                  HabitarCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recibir avisos',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        HabitarToggle(
                          value: _pushEnabled,
                          onChanged: (value) =>
                              setState(() => _pushEnabled = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: HabitarSpacing.lg),
                  if (_pushEnabled) ...[
                    Text(
                      'Horario silencioso',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: HabitarSpacing.xs),
                    Text(
                      'Opcional. Mientras dure, no vas a recibir avisos '
                      'push, aunque alguien complete una rutina.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: HabitarColors.mutedInk),
                    ),
                    const SizedBox(height: HabitarSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickTime(isStart: true),
                            child: Text(_quietStart == null
                                ? 'Desde'
                                : _quietStart!.format(context)),
                          ),
                        ),
                        const SizedBox(width: HabitarSpacing.sm),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickTime(isStart: false),
                            child: Text(_quietEnd == null
                                ? 'Hasta'
                                : _quietEnd!.format(context)),
                          ),
                        ),
                      ],
                    ),
                    if (_quietStart != null || _quietEnd != null) ...[
                      const SizedBox(height: HabitarSpacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _clearQuietHours,
                          child: const Text('Quitar horario silencioso'),
                        ),
                      ),
                    ],
                    const SizedBox(height: HabitarSpacing.md),
                  ],
                  const SizedBox(height: HabitarSpacing.lg),
                  FilledButton(
                    onPressed: _saving || _userId == null ? null : _save,
                    child: Text(_saving ? 'Guardando...' : 'Guardar'),
                  ),
                ],
              ),
      ),
    );
  }
}
