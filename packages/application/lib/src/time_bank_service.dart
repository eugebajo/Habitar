import 'package:habitar_domain/domain.dart';
import 'package:uuid/uuid.dart';

import 'repositories.dart';

const _uuid = Uuid();

class GrantTimeBenefitInput {
  const GrantTimeBenefitInput({
    required this.profileId,
    required this.description,
    required this.minutes,
    required this.idempotencyKey,
    this.routineId,
    this.habitId,
    this.kind = BenefitKind.digitalTime,
    this.dailyLimitMinutes,
    this.expiresAt,
    this.accumulationAllowed = true,
    this.sourceAction,
  });

  final String profileId;
  final String description;
  final int minutes;
  final String idempotencyKey;
  final String? routineId;
  final String? habitId;
  final BenefitKind kind;
  final int? dailyLimitMinutes;
  final DateTime? expiresAt;
  final bool accumulationAllowed;
  final String? sourceAction;
}

class TimeBankService {
  const TimeBankService({required this.repository});

  final TimeBankRepository repository;

  Future<TimeBankSummary> summaryForProfile(String profileId) async {
    final benefits = await repository.benefitsForProfile(profileId);
    final available = benefits
        .where((benefit) => benefit.status == BenefitStatus.available)
        .fold<int>(0, (total, benefit) => total + benefit.balanceMinutes);
    final used =
        benefits.fold<int>(0, (total, benefit) => total + benefit.minutesUsed);
    return TimeBankSummary(
      profileId: profileId,
      availableMinutes: available,
      usedMinutes: used,
      benefits: benefits,
    );
  }

  Future<TimeBankBenefit> grantTime(GrantTimeBenefitInput input) async {
    if (input.minutes <= 0) {
      throw ArgumentError.value(
          input.minutes, 'minutes', 'Minutes must be positive.');
    }
    final existing = await repository.benefitsForProfile(input.profileId);
    for (final benefit in existing) {
      if (benefit.idempotencyKey == input.idempotencyKey) {
        return benefit;
      }
    }
    final now = DateTime.now();
    return repository.saveBenefit(
      TimeBankBenefit(
        metadata: EntityMetadata(
          id: _uuid.v4(),
          createdAt: now,
          updatedAt: now,
          ownerId: input.profileId,
        ),
        profileId: input.profileId,
        routineId: input.routineId,
        habitId: input.habitId,
        kind: input.kind,
        description: input.description,
        minutesEarned: input.minutes,
        dailyLimitMinutes: input.dailyLimitMinutes,
        expiresAt: input.expiresAt,
        accumulationAllowed: input.accumulationAllowed,
        sourceAction: input.sourceAction,
        idempotencyKey: input.idempotencyKey,
      ),
    );
  }

  Future<TimeBankSummary> useMinutes({
    required String profileId,
    required int minutes,
    String? approvedByAdultId,
  }) async {
    if (minutes <= 0) {
      throw ArgumentError.value(
          minutes, 'minutes', 'Minutes must be positive.');
    }
    var remaining = minutes;
    final benefits = await repository.benefitsForProfile(profileId);
    for (final benefit in benefits.where((item) => item.hasBalance)) {
      if (remaining == 0) {
        break;
      }
      final amount = remaining > benefit.balanceMinutes
          ? benefit.balanceMinutes
          : remaining;
      remaining -= amount;
      final updatedUsed = benefit.minutesUsed + amount;
      await repository.saveBenefit(
        benefit.copyWith(
          minutesUsed: updatedUsed,
          status: updatedUsed >= benefit.minutesEarned
              ? BenefitStatus.used
              : BenefitStatus.available,
          approvedByAdultId: approvedByAdultId,
        ),
      );
    }
    return summaryForProfile(profileId);
  }
}
