import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

enum LegalDocumentKind { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({
    super.key,
    required this.title,
    required this.kind,
  });

  final String title;
  final LegalDocumentKind kind;

  @override
  Widget build(BuildContext context) {
    final sections = switch (kind) {
      LegalDocumentKind.privacy => _privacySections,
      LegalDocumentKind.terms => _termsSections,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: HabitarPage(
        maxWidth: 820,
        children: [
          const SizedBox(height: HabitarSpacing.lg),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: HabitarSpacing.sm),
          Text(
            'Documento preliminar para la versión inicial de Habitar.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: HabitarColors.mutedInk),
          ),
          const SizedBox(height: HabitarSpacing.lg),
          for (final section in sections) ...[
            Text(section.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: HabitarSpacing.xs),
            Text(section.body),
            const SizedBox(height: HabitarSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}

const _privacySections = [
  _LegalSection(
    'Qué datos usamos',
    'Habitar puede usar datos de cuenta, perfiles familiares, rutinas, hábitos, progreso, preferencias de notificación y check-ins opcionales para prestar el servicio.',
  ),
  _LegalSection(
    'Para qué los usamos',
    'Usamos estos datos para crear el espacio familiar, permitir el acceso adulto, mostrar rutinas asignadas, resumir progreso y sincronizar información cuando la cuenta lo permita.',
  ),
  _LegalSection(
    'Datos de niños y adolescentes',
    'Los perfiles infantiles y adolescentes existen para acompañamiento familiar. Los adultos responsables administran rutinas, hábitos y configuraciones.',
  ),
  _LegalSection(
    'Seguridad',
    'La información se transmite mediante conexiones seguras. El espacio adulto está protegido por un paso de confirmación y la base remota debe usar reglas de acceso por cuenta.',
  ),
  _LegalSection(
    'Contacto',
    'Para consultas de privacidad o soporte, escribe a soporte@habitarpy.com.',
  ),
];

const _termsSections = [
  _LegalSection(
    'Uso de Habitar',
    'Habitar es una herramienta de organización familiar para rutinas, hábitos y acompañamiento diario. No reemplaza orientación médica, psicológica, educativa ni profesional.',
  ),
  _LegalSection(
    'Responsabilidad adulta',
    'El espacio adulto debe ser usado por madres, padres, tutores, cuidadores o profesionales autorizados. Los niños y adolescentes no deben crear sus propias rutinas ni hábitos desde su modo personal.',
  ),
  _LegalSection(
    'Contenido y decisiones',
    'Las rutinas, hábitos, cuentos y apoyos deben revisarse según la situación de cada familia. El adulto responsable decide qué acompañamiento corresponde.',
  ),
  _LegalSection(
    'Cuenta y seguridad',
    'La persona adulta responsable debe cuidar sus credenciales y mantener actualizado el acceso a su correo de cuenta.',
  ),
  _LegalSection(
    'Contacto',
    'Para soporte o consultas sobre estos términos, escribí a soporte@habitarpy.com.',
  ),
];
