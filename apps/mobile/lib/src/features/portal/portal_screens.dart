import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

import '../../components/adult_shell.dart';

class AdultSectionScreen extends StatelessWidget {
  const AdultSectionScreen({super.key, required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      'routines' => const _RoutinesSection(),
      'progress' => const _ProgressSection(),
      'habits' => _GenericAdultSection(
          title: 'Hábitos',
          subtitle: 'Activá como máximo tres cambios pequeños a la vez.',
          icon: Icons.eco_rounded,
          actionPath: '/habits',
          actionLabel: 'Crear hábito',
        ),
      'settings' => _GenericAdultSection(
          title: 'Configuración',
          subtitle: 'Ajustá accesibilidad, privacidad y experiencia sensorial.',
          icon: Icons.tune_rounded,
          actionPath: '/privacy',
          actionLabel: 'Privacidad',
        ),
      _ => _GenericAdultSection(
          title: 'Habitar',
          subtitle: 'Un espacio familiar para avanzar paso a paso.',
          icon: Icons.favorite_rounded,
          actionPath: '/dashboard',
          actionLabel: 'Ir al inicio',
        ),
    };
  }
}

class _RoutinesSection extends StatelessWidget {
  const _RoutinesSection();

  @override
  Widget build(BuildContext context) => AdultPage(
        title: 'Rutinas',
        subtitle: 'Organizá el día de Tomi con rutinas claras y previsibles.',
        action: FilledButton.icon(
          onPressed: () => context.go('/routine/create'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nueva rutina'),
        ),
        child: Column(
          children: [
            _ProfileSelector(onTap: () => context.go('/profiles')),
            const SizedBox(height: 16),
            const _RoutineTile(
                icon: Icons.wb_sunny_outlined,
                title: 'Mañana',
                time: '07:00',
                steps: '5 pasos',
                status: 'Completada',
                statusColor: HabitarColors.surfaceMist),
            const SizedBox(height: 12),
            const _RoutineTile(
                icon: Icons.backpack_outlined,
                title: 'Después de la escuela',
                time: '16:30',
                steps: '4 pasos',
                status: 'Pendiente',
                statusColor: HabitarColors.surfaceWarm),
            const SizedBox(height: 12),
            const _RoutineTile(
                icon: Icons.directions_walk_rounded,
                title: 'Prepararse para salir',
                time: '18:30',
                steps: '3 pasos',
                status: 'Activa',
                statusColor: HabitarColors.surfaceMist),
            const SizedBox(height: 12),
            const _RoutineTile(
                icon: Icons.nightlight_round,
                title: 'Noche',
                time: '20:30',
                steps: '4 pasos',
                status: 'Programada',
                statusColor: Color(0xFFEAF0F8)),
            const SizedBox(height: 18),
            const HabitarConversationCard(
              title: 'Consejo de Habitar',
              body:
                  'La constancia crea seguridad. Repetir las rutinas todos los días ayuda a Tomi a sentirse más tranquilo.',
              color: HabitarColors.surfaceMist,
              leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.favorite_border_rounded,
                      color: HabitarColors.deepGreen)),
            ),
          ],
        ),
      );
}

class _ProfileSelector extends StatelessWidget {
  const _ProfileSelector({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => HabitarCard(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: const Row(children: [
          HabitarAvatar(label: 'Tomi', size: 50),
          SizedBox(width: 12),
          Expanded(
              child: Text('Tomi',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: HabitarColors.deepGreen,
                      fontSize: 18))),
          Icon(Icons.keyboard_arrow_down_rounded),
        ]),
      );
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile(
      {required this.icon,
      required this.title,
      required this.time,
      required this.steps,
      required this.status,
      required this.statusColor});
  final IconData icon;
  final String title;
  final String time;
  final String steps;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) => HabitarCard(
        child: Column(children: [
          Row(children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                  color: HabitarColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, color: HabitarColors.deepGreen, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Wrap(spacing: 12, children: [
                    _MiniMeta(icon: Icons.schedule_rounded, label: time),
                    _MiniMeta(
                        icon: Icons.format_list_bulleted_rounded, label: steps),
                  ]),
                ])),
            HabitarPill(
                label: status,
                icon: Icons.check_circle_rounded,
                color: statusColor),
          ]),
          const Divider(height: 28, color: HabitarColors.line),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _TileAction(icon: Icons.edit_outlined, label: 'Editar'),
                _TileAction(
                    icon: Icons.content_copy_rounded, label: 'Duplicar'),
                _TileAction(
                    icon: Icons.pause_circle_outline_rounded, label: 'Pausar'),
              ]),
        ]),
      );
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: HabitarColors.mutedInk),
        const SizedBox(width: 5),
        Text(label)
      ]);
}

class _TileAction extends StatelessWidget {
  const _TileAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 6), Text(label)]);
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection();

  @override
  Widget build(BuildContext context) => AdultPage(
        title: 'Progreso semanal',
        subtitle: 'Una mirada simple, sin comparaciones ni castigos.',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HabitarCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.bar_chart_rounded,
                    color: HabitarColors.primaryGreen),
                const SizedBox(width: 10),
                Text('Resumen semanal',
                    style: Theme.of(context).textTheme.titleLarge)
              ]),
              const SizedBox(height: 22),
              Row(children: [
                const ProgressRing(value: .82, size: 142),
                const SizedBox(width: 22),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('82% completado\nesta semana',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      const Text('49 de 60 pasos completados'),
                      const SizedBox(height: 14),
                      const _LegendDot(
                          color: HabitarColors.primaryGreen,
                          label: 'Completado (49)'),
                      const SizedBox(height: 8),
                      const _LegendDot(
                          color: Color(0xFFEADDC8), label: 'Pendiente (11)'),
                    ])),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio:
                MediaQuery.sizeOf(context).width > 700 ? 1.05 : 2.6,
            children: const [
              _ProgressStat(
                  icon: Icons.check_circle_outline,
                  value: '18',
                  label: 'Rutinas\ncompletadas',
                  note: 'esta semana'),
              _ProgressStat(
                  icon: Icons.eco_rounded,
                  value: '7',
                  label: 'Hábitos\nen marcha',
                  note: 'siguiendo su ritmo'),
              _ProgressStat(
                  icon: Icons.star_rounded,
                  value: '¡Muy bien!',
                  label: 'Logro reciente',
                  note: '7 días seguidos ordenando su cuarto'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Reporte y logros',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Descargar reporte PDF'))),
            const SizedBox(width: 12),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Compartir'))),
          ]),
          const SizedBox(height: 16),
          HabitarCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text('Reporte semanal de Tomi',
                        style: Theme.of(context).textTheme.titleLarge)),
                const Text('Generado hoy',
                    style: TextStyle(color: HabitarColors.mutedInk))
              ]),
              const SizedBox(height: 16),
              const _CategoryBar(label: 'Rutinas', value: .9),
              const _CategoryBar(label: 'Organización', value: .8),
              const _CategoryBar(label: 'Autonomía', value: .75),
              const _CategoryBar(label: 'Tiempo libre', value: .6),
            ]),
          ),
        ]),
      );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [
        CircleAvatar(radius: 7, backgroundColor: color),
        const SizedBox(width: 8),
        Text(label)
      ]);
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.note});
  final IconData icon;
  final String value;
  final String label;
  final String note;
  @override
  Widget build(BuildContext context) => HabitarCard(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(
              backgroundColor: HabitarColors.surfaceMist,
              child: Icon(icon, color: HabitarColors.deepGreen)),
          const SizedBox(height: 10),
          Text(value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          Text(label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
          Text(note, textAlign: TextAlign.center),
        ]),
      );
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor: HabitarColors.surfaceMist,
                      color: HabitarColors.primaryGreen))),
          const SizedBox(width: 10),
          Text('${(value * 100).round()}%'),
        ]),
      );
}

class _GenericAdultSection extends StatelessWidget {
  const _GenericAdultSection(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.actionPath,
      required this.actionLabel});
  final String title;
  final String subtitle;
  final IconData icon;
  final String actionPath;
  final String actionLabel;
  @override
  Widget build(BuildContext context) => AdultPage(
        title: title,
        subtitle: subtitle,
        action: FilledButton.icon(
            onPressed: () => context.go(actionPath),
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel)),
        child: GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 800 ? 3 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [
            _Stat(icon: icon, label: subtitle, value: 'Todo listo'),
            const _Stat(
                icon: Icons.check_circle_outline,
                label: 'Completados esta semana',
                value: '8 pasos'),
            const _Stat(
                icon: Icons.favorite_outline,
                label: 'Logro reciente',
                value: 'Pidió ayuda'),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => HabitarCard(
        child: Row(children: [
          CircleAvatar(
              backgroundColor: HabitarColors.surfaceMist,
              child: Icon(icon, color: HabitarColors.deepGreen)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(value, style: Theme.of(context).textTheme.titleMedium),
                Text(label,
                    maxLines: 2,
                    style: const TextStyle(color: HabitarColors.mutedInk)),
              ])),
        ]),
      );
}

class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: HabitarPage(
          maxWidth: 620,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          children: [
            const Center(child: HabitarLogo(size: 64)),
            const SizedBox(height: 20),
            Text('Hola, Tomi',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall),
            Text('Viernes por la tarde',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: HabitarColors.primaryGreen)),
            const SizedBox(height: 24),
            _ChildPriorityCard(
                color: HabitarColors.surfaceMist,
                art: 'bag',
                label: 'Ahora',
                title: 'Prepararnos\npara salir',
                body: 'Tres pasos claros, uno a la vez.',
                action: 'Empezar',
                onTap: () => context.go('/routine/player')),
            const SizedBox(height: 12),
            _ChildPriorityCard(
                color: HabitarColors.card,
                art: 'home',
                label: 'Después',
                title: 'Tiempo libre',
                body: '',
                action: 'Ver',
                onTap: () => context.go('/child/achievements')),
            const SizedBox(height: 12),
            _ChildPriorityCard(
                color: HabitarColors.surfaceMist,
                art: 'heart',
                label: 'Pedir ayuda',
                title: 'No tengo que\nhacerlo solo',
                body: '',
                action: 'Ayuda',
                onTap: () => context.go('/child/emotions')),
            const SizedBox(height: 18),
            FilledButton.icon(
                onPressed: () => showAdultPin(context),
                icon: const Icon(Icons.groups_rounded),
                label: const Text('Espacio adulto')),
          ],
        ),
      );
}

class _ChildPriorityCard extends StatelessWidget {
  const _ChildPriorityCard(
      {required this.color,
      required this.art,
      required this.label,
      required this.title,
      required this.body,
      required this.action,
      required this.onTap});
  final Color color;
  final String art;
  final String label;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => HabitarCard(
        color: color,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  HabitarPill(
                      label: label, color: Colors.white.withValues(alpha: .5)),
                  const SizedBox(height: 12),
                  Text(title, style: Theme.of(context).textTheme.displaySmall),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(body, style: Theme.of(context).textTheme.bodyLarge)
                  ],
                ])),
            SizedBox(
                width: 130,
                height: 120,
                child: HabitarSoftIllustration(label: art)),
          ]),
          const SizedBox(height: 14),
          OutlinedButton(
              onPressed: onTap,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(action),
                    const SizedBox(width: 14),
                    const Icon(Icons.arrow_forward_rounded)
                  ])),
        ]),
      );
}

class TeenHomeScreen extends StatelessWidget {
  const TeenHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mi espacio'), actions: [
          IconButton(
              tooltip: 'Privacidad',
              onPressed: () => context.go('/teen/privacy'),
              icon: const Icon(Icons.shield_outlined))
        ]),
        body: HabitarPage(children: [
          Text('Buenas tardes, Alex',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Tu día, a tu ritmo.',
              style: TextStyle(color: HabitarColors.mutedInk)),
          const SizedBox(height: 24),
          const _TeenTile(
              icon: Icons.flag_outlined,
              title: 'Objetivo de hoy',
              value: 'Preparar la mochila'),
          const _TeenTile(
              icon: Icons.task_alt_rounded,
              title: 'Hábitos activos',
              value: '2 de 3 completados'),
          const _TeenTile(
              icon: Icons.insights_rounded,
              title: 'Mi progreso',
              value: '4 días esta semana'),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: () => context.go('/teen/reflection'),
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Reflexión diaria')),
          TextButton(
              onPressed: () => showAdultPin(context),
              child: const Text('Entrar al espacio adulto')),
        ]),
      );
}

class _TeenTile extends StatelessWidget {
  const _TeenTile(
      {required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: HabitarCard(
            child: ListTile(
                leading: Icon(icon, color: HabitarColors.deepGreen),
                title: Text(title),
                subtitle: Text(value),
                trailing: const Icon(Icons.chevron_right))),
      );
}

class SimpleModeScreen extends StatelessWidget {
  const SimpleModeScreen(
      {super.key,
      required this.title,
      required this.message,
      this.teen = false});
  final String title;
  final String message;
  final bool teen;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: HabitarPage(children: [
        EmptyState(
            icon: teen ? Icons.lock_person_outlined : Icons.star_rounded,
            title: title,
            message: message),
        const SizedBox(height: 20),
        FilledButton(
            onPressed: () => context.pop(), child: const Text('Volver')),
      ]));
}

class AdultPinScreen extends StatelessWidget {
  const AdultPinScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Espacio adulto')),
        body: HabitarPage(children: [
          const EmptyState(
              icon: Icons.lock_outline,
              title: 'Verificar cuenta adulta',
              message:
                  'Las rutinas, hábitos y cambios familiares quedan protegidos.'),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: () => showAdultPin(context),
              child: const Text('Verificar acceso')),
        ]),
      );
}

void showAdultPin(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Verificar adulto'),
      content: const Text(
          'Para administrar rutinas, perfiles y recompensas, entrá con la cuenta adulta.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/login');
            },
            child: const Text('Entrar como adulto')),
      ],
    ),
  );
}
