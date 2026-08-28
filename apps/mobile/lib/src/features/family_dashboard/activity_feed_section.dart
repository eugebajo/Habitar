import 'package:flutter/material.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';

/// "Actividad reciente": the family-facing feed of what children/teens
/// completed. Read-only - there is no way to create, edit or delete an event
/// from Flutter; every row here was written by the backend when a routine
/// was completed (see RoutineSessionRepository.completeSession).
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key, required this.events});

  final List<FamilyActivityEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const HabitarCard(
        child: EmptyState(
          icon: Icons.emoji_events_outlined,
          title: 'Todavía no hay actividad',
          message:
              'Apenas alguien termine una rutina, va a aparecer acá para que toda la familia lo vea.',
        ),
      );
    }
    return HabitarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < events.length; index += 1) ...[
            if (index > 0) const Divider(height: 24, color: HabitarColors.line),
            _ActivityRow(event: events[index]),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});

  final FamilyActivityEvent event;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_rounded,
            color: HabitarColors.primaryGreen,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: event.profileDisplayName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const TextSpan(text: ' terminó '),
                    TextSpan(
                      text: '"${event.routineTitle}"',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatRelativeActivityTime(event.metadata.createdAt),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: HabitarColors.mutedInk),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Formats [when] the way the activity feed does: "justo ahora" / "hace N
/// minutos" for anything in the last hour, "hoy a las HH:MM" / "ayer a las
/// HH:MM" for the last two calendar days, and a full date otherwise. [now]
/// is injectable for tests; defaults to the real current time.
String formatRelativeActivityTime(DateTime when, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(when);

  if (diff.inSeconds < 60) {
    return 'justo ahora';
  }
  if (diff.inMinutes < 60) {
    final minutes = diff.inMinutes;
    return 'hace $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
  }
  if (_isSameDay(when, reference)) {
    return 'hoy a las ${_hhmm(when)}';
  }
  final yesterday = reference.subtract(const Duration(days: 1));
  if (_isSameDay(when, yesterday)) {
    return 'ayer a las ${_hhmm(when)}';
  }
  final datePart = when.year == reference.year
      ? '${when.day} de ${_monthName(when.month)}'
      : '${when.day} de ${_monthName(when.month)} de ${when.year}';
  return '$datePart a las ${_hhmm(when)}';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _hhmm(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

const _monthNames = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _monthName(int month) => _monthNames[month - 1];
