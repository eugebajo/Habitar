import 'package:habitar_domain/domain.dart';

import 'repositories.dart';

class AdultRegistrationInput {
  const AdultRegistrationInput({required this.displayName, required this.email, required this.password, required this.familyName});

  final String displayName;
  final String email;
  final String password;
  final String familyName;
}

class AdultRegistrationResult {
  const AdultRegistrationResult({required this.user, required this.family});

  final User user;
  final Family family;
}

class AdultRegistrationService {
  const AdultRegistrationService({required this.authRepository, required this.familyRepository});

  final AuthRepository authRepository;
  final FamilyRepository familyRepository;

  Future<AdultRegistrationResult> register(AdultRegistrationInput input) async {
    final user = await authRepository.registerAdult(
      displayName: input.displayName,
      email: input.email,
      password: input.password,
    );
    final family = await familyRepository.createFamily(ownerUserId: user.metadata.id, name: input.familyName);
    return AdultRegistrationResult(user: user, family: family);
  }
}
