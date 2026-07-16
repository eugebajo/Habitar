import 'package:habitar_domain/domain.dart';

import 'repositories.dart';

class CreateProfileInput {
  const CreateProfileInput({
    required this.familyId,
    required this.displayName,
    required this.age,
    required this.kind,
  });

  final String familyId;
  final String displayName;
  final int age;
  final ProfileKind kind;
}

class ProfileService {
  const ProfileService(this.repository);

  final ProfileRepository repository;

  Future<AppEntity> createProfile(CreateProfileInput input) {
    if (input.kind == ProfileKind.child) {
      return repository.createChildProfile(
          familyId: input.familyId,
          displayName: input.displayName,
          age: input.age);
    }
    return repository.createTeenProfile(
        familyId: input.familyId,
        displayName: input.displayName,
        age: input.age);
  }
}
