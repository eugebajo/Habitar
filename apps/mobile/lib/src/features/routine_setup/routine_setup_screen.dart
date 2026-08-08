import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';

import '../../dependencies.dart';

class RoutineSetupScreen extends ConsumerStatefulWidget {
  const RoutineSetupScreen({super.key, this.routineId});

  final String? routineId;

  @override
  ConsumerState<RoutineSetupScreen> createState() => _RoutineSetupScreenState();
}

class _RoutineSetupScreenState extends ConsumerState<RoutineSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Prepararse para salir');
  final _durationController = TextEditingController(text: '15');
  final _leadReminderController = TextEditingController(text: '10');
  final _contextController = TextEditingController(text: 'Casa');
  final _minimumVersionController =
      TextEditingController(text: 'Hacer los dos primeros pasos');
  final _benefitController =
      TextEditingController(text: 'Tiempo tranquilo al terminar');
  final _maxReminderController = TextEditingController(text: '2');
  final _reminderIntervalController = TextEditingController(text: '5');
  final _stepControllers = [
    TextEditingController(text: 'Guardar la botella'),
    TextEditingController(text: 'Ponerse los zapatos'),
    TextEditingController(text: 'Tomar la mochila'),
  ];
  final _selectedWeekdays = <int>{1, 2, 3, 4, 5};
  TimeOfDay? _scheduledTime = const TimeOfDay(hour: 18, minute: 30);
  RoutineRepeatPolicy _repeatPolicy = RoutineRepeatPolicy.weekly;
  String? _responsibleAdultProfileId;
  var _vibrationEnabled = true;
  var _soundEnabled = false;
  var _silentNotification = false;
  var _canPostpone = true;
  var _canRequestHelp = true;
  Routine? _editingRoutine;
  var _isLoading = false;
  String? _loadError;
  var _isSubmitting = false;

  bool get _isEditing => widget.routineId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadRoutine();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _leadReminderController.dispose();
    _contextController.dispose();
    _minimumVersionController.dispose();
    _benefitController.dispose();
    _maxReminderController.dispose();
    _reminderIntervalController.dispose();
    for (final controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileId = ref.watch(currentProfileIdProvider);
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'Editar rutina' : 'Preparar un camino')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _RoutineLoadError(
                    message: _loadError!,
                    onRetry: _loadRoutine,
                  )
                : _buildForm(context, profileId),
      ),
    );
  }

  Widget _buildForm(BuildContext context, String? profileId) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(HabitarSpacing.lg),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const HabitarMoment(
                    title: '¿Qué necesita pasar primero?',
                    body:
                        'Tres pasos alcanzan. Sumamos horario y avisos suaves para que sea más fácil empezar.',
                    color: HabitarColors.surfaceMist,
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  TextFormField(
                    controller: _titleController,
                    decoration:
                        const InputDecoration(labelText: 'Nombre del momento'),
                    validator: _required,
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  _SectionTitle('Horario'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickScheduledTime,
                        icon: const Icon(Icons.schedule_rounded),
                        label: Text(_scheduledTime == null
                            ? 'Agregar horario'
                            : 'Horario: ${_scheduledTime!.format(context)}'),
                      ),
                      DropdownButton<RoutineRepeatPolicy>(
                        value: _repeatPolicy,
                        items: const [
                          DropdownMenuItem(
                              value: RoutineRepeatPolicy.once,
                              child: Text('Una vez')),
                          DropdownMenuItem(
                              value: RoutineRepeatPolicy.weekly,
                              child: Text('Semanal')),
                          DropdownMenuItem(
                              value: RoutineRepeatPolicy.weekdays,
                              child: Text('Días hábiles')),
                          DropdownMenuItem(
                              value: RoutineRepeatPolicy.daily,
                              child: Text('Todos los días')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _repeatPolicy = value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: HabitarSpacing.sm),
                  _WeekdayPicker(
                    selected: _selectedWeekdays,
                    onToggle: (day) {
                      setState(() {
                        if (_selectedWeekdays.contains(day)) {
                          _selectedWeekdays.remove(day);
                        } else {
                          _selectedWeekdays.add(day);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Duración estimada (min)'),
                          validator: _positiveNumber,
                        ),
                      ),
                      const SizedBox(width: HabitarSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _leadReminderController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Aviso antes (min)'),
                          validator: _nonNegativeNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  if (profileId != null)
                    _ResponsibleAdultPicker(
                      profileId: profileId,
                      selectedId: _responsibleAdultProfileId,
                      onChanged: (value) =>
                          setState(() => _responsibleAdultProfileId = value),
                    ),
                  const SizedBox(height: HabitarSpacing.md),
                  _SectionTitle('Pasos'),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stepControllers.length,
                    onReorderItem: _reorderStep,
                    itemBuilder: (context, index) {
                      final controller = _stepControllers[index];
                      return Padding(
                        key: ValueKey(controller),
                        padding:
                            const EdgeInsets.only(bottom: HabitarSpacing.md),
                        child: Row(
                          children: [
                            const Icon(Icons.drag_indicator_rounded,
                                color: HabitarColors.mutedInk),
                            const SizedBox(width: HabitarSpacing.xs),
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                    labelText: 'Pequeño paso ${index + 1}'),
                                validator: _required,
                              ),
                            ),
                            if (_stepControllers.length > 3)
                              IconButton(
                                tooltip: 'Quitar paso',
                                onPressed: () => _removeStep(index),
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _addStep,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Agregar paso'),
                    ),
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  _SectionTitle('Apoyos'),
                  TextFormField(
                    controller: _contextController,
                    decoration:
                        const InputDecoration(labelText: 'Hogar o contexto'),
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  TextFormField(
                    controller: _minimumVersionController,
                    decoration:
                        const InputDecoration(labelText: 'Vers?ón mínima'),
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  TextFormField(
                    controller: _benefitController,
                    decoration:
                        const InputDecoration(labelText: 'Beneficio opcional'),
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _maxReminderController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Máx. recordatorios'),
                          validator: _nonNegativeNumber,
                        ),
                      ),
                      const SizedBox(width: HabitarSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _reminderIntervalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Intervalo (min)'),
                          validator: _positiveNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HabitarSpacing.sm),
                  SwitchListTile(
                    value: _vibrationEnabled,
                    onChanged: (value) =>
                        setState(() => _vibrationEnabled = value),
                    title: const Text('Vibración suave'),
                  ),
                  SwitchListTile(
                    value: _soundEnabled,
                    onChanged: _silentNotification
                        ? null
                        : (value) => setState(() => _soundEnabled = value),
                    title: const Text('Sonido breve'),
                  ),
                  SwitchListTile(
                    value: _silentNotification,
                    onChanged: (value) => setState(() {
                      _silentNotification = value;
                      if (value) _soundEnabled = false;
                    }),
                    title: const Text('Aviso silencioso'),
                  ),
                  SwitchListTile(
                    value: _canPostpone,
                    onChanged: (value) => setState(() => _canPostpone = value),
                    title: const Text('Permitir posponer'),
                  ),
                  SwitchListTile(
                    value: _canRequestHelp,
                    onChanged: (value) =>
                        setState(() => _canRequestHelp = value),
                    title: const Text('Permitir pedir ayuda'),
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(_isSubmitting
                        ? 'Guardando...'
                        : _isEditing
                            ? 'Guardar cambios'
                            : 'Guardar rutina'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Completa este dato';
    }
    return null;
  }

  String? _positiveNumber(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Usa un número mayor a 0';
    }
    return null;
  }

  String? _nonNegativeNumber(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) {
      return 'Usa 0 o más';
    }
    return null;
  }

  int? _intValue(TextEditingController controller) {
    return int.tryParse(controller.text.trim());
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _pickScheduledTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _scheduledTime = time);
    }
  }

  Future<void> _loadRoutine() async {
    final routineId = widget.routineId;
    if (routineId == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final repository = ref.read(routineRepositoryProvider);
      final routine = await repository.routineById(routineId);
      if (routine == null) {
        throw StateError('No encontramos esta rutina.');
      }
      final steps = await repository.stepsForRoutine(routineId);
      _applyRoutine(routine, steps);
    } catch (error) {
      _loadError = 'No pudimos cargar la rutina. Intentá nuevamente.';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyRoutine(Routine routine, List<RoutineStep> steps) {
    _editingRoutine = routine;
    _titleController.text = routine.title;
    _durationController.text =
        (routine.estimatedDurationMinutes ?? 15).toString();
    _leadReminderController.text = routine.leadReminderMinutes.toString();
    _contextController.text = routine.contextLabel ?? '';
    _minimumVersionController.text = routine.minimumVersion ?? '';
    _benefitController.text = routine.benefitDescription ?? '';
    _maxReminderController.text = routine.maxReminderCount.toString();
    _reminderIntervalController.text =
        routine.reminderIntervalMinutes.toString();
    _selectedWeekdays
      ..clear()
      ..addAll(routine.weekdays);
    _scheduledTime = routine.hasSchedule
        ? TimeOfDay(
            hour: routine.scheduledHour!, minute: routine.scheduledMinute!)
        : null;
    _repeatPolicy = routine.repeatPolicy;
    _responsibleAdultProfileId = routine.responsibleAdultProfileId;
    _vibrationEnabled = routine.vibrationEnabled;
    _soundEnabled = routine.soundEnabled;
    _silentNotification = routine.silentNotification;
    _canPostpone = routine.canPostpone;
    _canRequestHelp = routine.canRequestHelp;
    for (final controller in _stepControllers) {
      controller.dispose();
    }
    _stepControllers
      ..clear()
      ..addAll(steps.map((step) => TextEditingController(text: step.title)));
  }

  void _reorderStep(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final controller = _stepControllers.removeAt(oldIndex);
      _stepControllers.insert(newIndex, controller);
    });
  }

  void _addStep() {
    setState(() => _stepControllers.add(TextEditingController()));
  }

  void _removeStep(int index) {
    final controller = _stepControllers.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      context.go('/profile');
      return;
    }
    setState(() => _isSubmitting = true);
    final repository = ref.read(routineRepositoryProvider);
    try {
      if (_isEditing) {
        final routine = _routineFromForm(_editingRoutine!);
        await repository.updateRoutine(
          routine: routine,
          stepTitles: _stepTitles(),
        );
      } else {
        await repository.createRoutine(
          profileId: profileId,
          title: _titleController.text.trim(),
          stepTitles: _stepTitles(),
          weekdays: _selectedWeekdays.toList(growable: false)..sort(),
          scheduledHour: _scheduledTime?.hour,
          scheduledMinute: _scheduledTime?.minute,
          estimatedDurationMinutes: _intValue(_durationController),
          leadReminderMinutes: _intValue(_leadReminderController) ?? 10,
          repeatPolicy: _repeatPolicy,
          responsibleAdultProfileId: _responsibleAdultProfileId,
          contextLabel: _optionalText(_contextController),
          minimumVersion: _optionalText(_minimumVersionController),
          benefitDescription: _optionalText(_benefitController),
          maxReminderCount: _intValue(_maxReminderController) ?? 2,
          reminderIntervalMinutes: _intValue(_reminderIntervalController) ?? 5,
          vibrationEnabled: _vibrationEnabled,
          soundEnabled: _soundEnabled,
          silentNotification: _silentNotification,
          canPostpone: _canPostpone,
          canRequestHelp: _canRequestHelp,
        );
      }
      if (mounted) {
        context.go('/routines');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos guardar la rutina.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  List<String> _stepTitles() => _stepControllers
      .map((controller) => controller.text.trim())
      .where((title) => title.isNotEmpty)
      .toList(growable: false);

  Routine _routineFromForm(Routine current) => Routine(
        metadata: current.metadata,
        profileId: current.profileId,
        title: _titleController.text.trim(),
        stepIds: current.stepIds,
        weekdays: _selectedWeekdays.toList(growable: false)..sort(),
        scheduledHour: _scheduledTime?.hour,
        scheduledMinute: _scheduledTime?.minute,
        estimatedDurationMinutes: _intValue(_durationController),
        leadReminderMinutes: _intValue(_leadReminderController) ?? 10,
        repeatPolicy: _repeatPolicy,
        responsibleAdultProfileId: _responsibleAdultProfileId,
        contextLabel: _optionalText(_contextController),
        minimumVersion: _optionalText(_minimumVersionController),
        benefitDescription: _optionalText(_benefitController),
        maxReminderCount: _intValue(_maxReminderController) ?? 2,
        reminderIntervalMinutes: _intValue(_reminderIntervalController) ?? 5,
        vibrationEnabled: _vibrationEnabled,
        soundEnabled: _soundEnabled,
        silentNotification: _silentNotification,
        canPostpone: _canPostpone,
        canRequestHelp: _canRequestHelp,
      );
}

class _RoutineLoadError extends StatelessWidget {
  const _RoutineLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: HabitarConversationCard(
        title: 'Rutina no disponible',
        body: message,
        color: HabitarColors.surfaceWarm,
        child: OutlinedButton(
          onPressed: onRetry,
          child: const Text('Reintentar'),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onToggle});

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  static const _days = [
    (1, 'L'),
    (2, 'M'),
    (3, 'Mi'),
    (4, 'J'),
    (5, 'V'),
    (6, 'S'),
    (7, 'D'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final day in _days)
          FilterChip(
            label: Text(day.$2),
            selected: selected.contains(day.$1),
            onSelected: (_) => onToggle(day.$1),
          ),
      ],
    );
  }
}

class _ResponsibleAdultPicker extends ConsumerWidget {
  const _ResponsibleAdultPicker({
    required this.profileId,
    required this.selectedId,
    required this.onChanged,
  });

  final String profileId;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<AdultProfile>>(
      future: ref
          .watch(adultProfileServiceProvider)
          .adultProfilesForProfile(profileId),
      builder: (context, snapshot) {
        final adults = snapshot.data ?? const <AdultProfile>[];
        if (adults.isEmpty) {
          return const Text(
            'Podés asignar un adulto responsable cuando el equipo adulto esté cargado.',
            style: TextStyle(color: HabitarColors.mutedInk),
          );
        }
        return DropdownButtonFormField<String?>(
          initialValue: selectedId,
          decoration: const InputDecoration(labelText: 'Adulto responsable'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Sin asignar'),
            ),
            for (final adult in adults)
              DropdownMenuItem<String?>(
                value: adult.metadata.id,
                child: Text(adult.displayName),
              ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}
