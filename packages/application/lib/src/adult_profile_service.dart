import 'package:habitar_domain/domain.dart';

import 'repositories.dart';

class CreateAdultProfileInput {
  const CreateAdultProfileInput({
    required this.familyId,
    required this.profileId,
    required this.displayName,
    required this.kind,
    this.email,
    this.roleLabel,
  });

  final String familyId;
  final String profileId;
  final String displayName;
  final AdultProfileKind kind;
  final String? email;
  final String? roleLabel;
}

class AdultProfileService {
  const AdultProfileService({required this.repository});

  final AdultProfileRepository repository;

  Future<AdultProfile> createAdultProfile(CreateAdultProfileInput input) {
    return repository.createAdultProfile(
      familyId: input.familyId,
      profileId: input.profileId,
      displayName: input.displayName,
      kind: input.kind,
      email: input.email,
      roleLabel: input.roleLabel,
    );
  }

  Future<List<AdultProfile>> adultProfilesForProfile(String profileId) {
    return repository.adultProfilesForProfile(profileId);
  }
}
