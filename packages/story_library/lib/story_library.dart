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
        body: 'Nico miraba su mochila abierta. Habia una botella, un cuaderno y una campera. Todo parecia mucho junto. Respiro una vez y dijo: necesito una pista. Su mama senalo la botella. Nico la guardo. Despues eligio el cuaderno. Cuando termino, la mochila ya no parecia una montana. Era solo una mochila esperando paso a paso.',
      ),
      durationMinutes: 3,
      mainEmotion: 'agobio',
      questions: ['Que hizo Nico cuando todo parecia mucho?', 'Que pista te gustaria pedir hoy?'],
      activity: 'Elegir una tarea pequena y pedir una pista antes de empezar.',
    ),
    DemoStoryContent(
      story: Story(
        metadata: metadata('story-10-13-change'),
        title: 'El martes cambio de forma',
        ageRange: '10-13',
        value: 'aceptar cambios',
        body: 'El martes tenia una forma conocida: clase, merienda, tarea y dibujo. Pero llovio y la clase de deporte cambio. Ana sintio calor en la cara. Su abuelo dibujo dos columnas: lo que cambio y lo que sigue igual. La merienda seguia. La tarea seguia. El dibujo seguia. El martes no desaparecio; solo habia cambiado una pieza.',
      ),
      durationMinutes: 4,
      mainEmotion: 'sorpresa',
      questions: ['Que parte del plan siguio igual?', 'Que ayuda cuando una pieza cambia?'],
      activity: 'Dibujar dos listas: cambio y sigue igual.',
    ),
    DemoStoryContent(
      story: Story(
        metadata: metadata('story-14-17-repair'),
        title: 'Despues del ruido',
        ageRange: '14-17',
        value: 'reparar un error',
        body: 'Leo cerro la puerta mas fuerte de lo que queria. No era lo que pensaba hacer; fue lo que salio cuando el ruido del dia se junto con el cansancio. Se sento cinco minutos sin hablar. Despues escribio: necesito bajar el volumen y despues puedo explicar. Cuando volvio, no tuvo que empezar desde cero. Reparar fue decir que paso y elegir el siguiente gesto.',
      ),
      durationMinutes: 5,
      mainEmotion: 'cansancio',
      questions: ['Que hizo Leo antes de volver a hablar?', 'Que gesto pequeno puede reparar algo?'],
      activity: 'Escribir una frase de reparacion sin culparse.',
    ),
  ];
}
