import 'package:habitar_domain/domain.dart';

class DemoStoryContent {
  const DemoStoryContent({
    required this.story,
    required this.durationMinutes,
    required this.mainEmotion,
    required this.questions,
    required this.activity,
    this.audioAvailable = false,
  });

  final Story story;
  final int durationMinutes;
  final String mainEmotion;
  final List<String> questions;
  final String activity;
  final bool audioAvailable;
}

List<Story> demoStories() {
  return demoStoryContent().map((content) => content.story).toList(growable: false);
}

List<DemoStoryContent> demoStoryContent() {
  final now = DateTime(2026, 1, 1);
  EntityMetadata metadata(String id) {
    return EntityMetadata(id: id, createdAt: now, updatedAt: now, ownerId: 'system');
  }

  return [
    DemoStoryContent(
      story: Story(
        metadata: metadata('story-6-9-help'),
        title: 'La mochila que esperaba',
        ageRange: '6-9',
        value: 'pedir ayuda',
        body: 'Nico miraba su mochila abierta. Había una botella, un cuaderno y una campera. Todo parecía mucho junto. Respiró una vez y dijo: necesito una pista. Su mamá señaló la botella. Nico la guardó. Después eligió el cuaderno. Cuando terminó, la mochila ya no parecía una montaña. Era solo una mochila esperando paso a paso.',
      ),
      durationMinutes: 3,
      mainEmotion: 'agobio',
      questions: ['¿Qué hizo Nico cuando todo parecía mucho?', '¿Qué pista te gustaría pedir hoy?'],
      activity: 'Elegir una tarea pequeña y pedir una pista antes de empezar.',
    ),
    DemoStoryContent(
      story: Story(
        metadata: metadata('story-10-13-change'),
        title: 'El martes cambió de forma',
        ageRange: '10-13',
        value: 'aceptar cambios',
        body: 'El martes tenía una forma conocida: clase, merienda, tarea y dibujo. Pero llovió y la clase de deporte cambió. Ana sintió calor en la cara. Su abuelo dibujó dos columnas: lo que cambió y lo que sigue igual. La merienda seguía. La tarea seguía. El dibujo seguía. El martes no desapareció; solo había cambiado una pieza.',
      ),
      durationMinutes: 4,
      mainEmotion: 'sorpresa',
      questions: ['¿Qué parte del plan siguió igual?', '¿Qué ayuda cuando una pieza cambia?'],
      activity: 'Dibujar dos listas: cambió y sigue igual.',
    ),
    DemoStoryContent(
      story: Story(
        metadata: metadata('story-14-17-repair'),
        title: 'Después del ruido',
        ageRange: '14-17',
        value: 'reparar un error',
        body: 'Leo cerró la puerta más fuerte de lo que quería. No era lo que pensaba hacer; fue lo que salió cuando el ruido del día se juntó con el cansancio. Se sentó cinco minutos sin hablar. Después escribió: necesito bajar el volumen y después puedo explicar. Cuando volvió, no tuvo que empezar desde cero. Reparar fue decir qué pasó y elegir el siguiente gesto.',
      ),
      durationMinutes: 5,
      mainEmotion: 'cansancio',
      questions: ['¿Qué hizo Leo antes de volver a hablar?', '¿Qué gesto pequeño puede reparar algo?'],
      activity: 'Escribir una frase de reparación sin culparse.',
    ),
  ];
}
