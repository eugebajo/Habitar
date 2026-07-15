import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_story_library/story_library.dart';

import '../../dependencies.dart';

class StoryLibraryScreen extends ConsumerStatefulWidget {
  const StoryLibraryScreen({super.key});

  @override
  ConsumerState<StoryLibraryScreen> createState() => _StoryLibraryScreenState();
}

class _StoryLibraryScreenState extends ConsumerState<StoryLibraryScreen> {
  DemoStoryContent? _selected;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final stories = ref.read(wellbeingServiceProvider).stories();
    final selected = _selected ?? stories.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentos')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HabitarSpacing.lg),
          children: [
            Text('Biblioteca demo',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: HabitarSpacing.md),
            for (final content in stories)
              Card(
                child: ListTile(
                  title: Text(content.story.title),
                  subtitle: Text(
                      '${content.story.ageRange} | ${content.story.value} | ${content.durationMinutes} min'),
                  selected:
                      selected.story.metadata.id == content.story.metadata.id,
                  onTap: () => setState(() => _selected = content),
                ),
              ),
            const SizedBox(height: HabitarSpacing.lg),
            _StoryReader(
                content: selected,
                onRead: () => _markRead(selected, favorite: false),
                onFavorite: () => _markRead(selected, favorite: true)),
            if (_message != null) ...[
              const SizedBox(height: HabitarSpacing.md),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(HabitarSpacing.md),
                      child: Text(_message!))),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _markRead(DemoStoryContent content,
      {required bool favorite}) async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      setState(() => _message = 'Primero crea un perfil.');
      return;
    }
    await ref.read(wellbeingServiceProvider).markStoryRead(
          profileId: profileId,
          storyId: content.story.metadata.id,
          favorite: favorite,
        );
    setState(() => _message = favorite
        ? 'Cuento guardado como favorito.'
        : 'Progreso del cuento guardado.');
  }
}

class _StoryReader extends StatelessWidget {
  const _StoryReader(
      {required this.content, required this.onRead, required this.onFavorite});

  final DemoStoryContent content;
  final VoidCallback onRead;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HabitarSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content.story.title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: HabitarSpacing.sm),
            Text('Valor: ${content.story.value}'),
            Text('Emocion principal: ${content.mainEmotion}'),
            Text(content.audioAvailable
                ? 'Audio disponible'
                : 'Audio pendiente'),
            const SizedBox(height: HabitarSpacing.md),
            Text(content.story.body),
            const SizedBox(height: HabitarSpacing.md),
            Text('Preguntas', style: Theme.of(context).textTheme.titleMedium),
            for (final question in content.questions) Text('- $question'),
            const SizedBox(height: HabitarSpacing.md),
            Text('Actividad: ${content.activity}'),
            const SizedBox(height: HabitarSpacing.md),
            Row(
              children: [
                FilledButton(
                    onPressed: onRead, child: const Text('Marcar leido')),
                const SizedBox(width: HabitarSpacing.sm),
                OutlinedButton(
                    onPressed: onFavorite, child: const Text('Favorito')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
