import 'package:habitar_domain/domain.dart';
import 'package:habitar_story_library/story_library.dart';

import 'repositories.dart';

class EmotionCheckInInput {
  const EmotionCheckInInput({
    required this.profileId,
    this.emotion,
    this.energyLevel,
    this.overloadLevel,
    this.needsQuiet = false,
    this.needsMovement = false,
    this.skipped = false,
  });

  final String profileId;
  final String? emotion;
  final int? energyLevel;
  final int? overloadLevel;
  final bool needsQuiet;
  final bool needsMovement;
  final bool skipped;
}

class SupportAction {
  const SupportAction(
      {required this.id, required this.label, required this.kind});

  final String id;
  final String label;
  final String kind;
}

class WellbeingService {
  const WellbeingService({
    required this.emotionRepository,
    required this.supportRepository,
    required this.storyProgressRepository,
  });

  final EmotionCheckInRepository emotionRepository;
  final SupportRequestRepository supportRepository;
  final StoryProgressRepository storyProgressRepository;

  List<SupportAction> supportActionsFor(EmotionCheckInInput input) {
    if (input.skipped) {
      return const [
        SupportAction(id: 'later', label: 'Responder despues', kind: 'pause')
      ];
    }
    final actions = <SupportAction>[
      const SupportAction(id: 'water', label: 'Tomar agua', kind: 'body'),
      const SupportAction(id: 'help', label: 'Pedir ayuda', kind: 'connection'),
    ];
    if ((input.overloadLevel ?? 0) >= 3 || input.needsQuiet) {
      actions.add(const SupportAction(
          id: 'quiet', label: 'Pausa sensorial', kind: 'sensory'));
      actions.add(const SupportAction(
          id: 'headphones', label: 'Usar auriculares', kind: 'sensory'));
    }
    if (input.needsMovement) {
      actions.add(const SupportAction(
          id: 'movement', label: 'Mover el cuerpo', kind: 'movement'));
    }
    return actions;
  }

  Future<EmotionCheckIn> recordCheckIn(EmotionCheckInInput input) {
    final now = DateTime.now();
    return emotionRepository.save(
      EmotionCheckIn(
        metadata: EntityMetadata(
            id: 'emotion-${now.microsecondsSinceEpoch}',
            createdAt: now,
            updatedAt: now,
            ownerId: input.profileId),
        profileId: input.profileId,
        emotion: input.skipped ? 'skip_now' : input.emotion,
        energyLevel: input.energyLevel,
      ),
    );
  }

  Future<SupportRequest> requestSupport(
      {required String profileId, required SupportAction action}) {
    final now = DateTime.now();
    return supportRepository.save(
      SupportRequest(
        metadata: EntityMetadata(
            id: 'support-${now.microsecondsSinceEpoch}',
            createdAt: now,
            updatedAt: now,
            ownerId: profileId),
        profileId: profileId,
        kind: action.kind,
        note: action.label,
      ),
    );
  }

  List<DemoStoryContent> stories() => demoStoryContent();

  Future<StoryProgress> markStoryRead(
      {required String profileId,
      required String storyId,
      bool favorite = false}) {
    final now = DateTime.now();
    return storyProgressRepository.save(
      StoryProgress(
        metadata: EntityMetadata(
            id: 'story-progress-$profileId-$storyId',
            createdAt: now,
            updatedAt: now,
            ownerId: profileId),
        storyId: storyId,
        profileId: profileId,
        isFavorite: favorite,
      ),
    );
  }

  Future<List<StoryProgress>> progressForProfile(String profileId) {
    return storyProgressRepository.progressForProfile(profileId);
  }
}
