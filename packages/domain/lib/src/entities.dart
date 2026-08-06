enum EntityStatus { active, paused, archived, deleted }

enum AccessScope { owner, family, caregiver, professional }

enum AdultProfileKind { parent, caregiver, professional, teacher }

enum ProfileKind { child, teen }

enum HabitStatus { proposed, newHabit, practicing, stable, paused, archived }

enum RoutineStepStatus { pending, active, completed, skipped, paused }

enum RoutineRepeatPolicy { once, daily, weekly, weekdays, custom }

enum BenefitKind {
  digitalTime,
  appTime,
  activity,
  story,
  music,
  adultTime,
  custom,
  recognition
}

enum BenefitStatus { available, pendingApproval, used, expired, corrected }

class AccessRule {
  const AccessRule({
    required this.scope,
    required this.canRead,
    required this.canWrite,
  });

  final AccessScope scope;
  final bool canRead;
  final bool canWrite;
}

class EntityMetadata {
  const EntityMetadata({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.ownerId,
    this.status = EntityStatus.active,
    this.accessRules = const [],
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String ownerId;
  final EntityStatus status;
  final List<AccessRule> accessRules;
}

abstract class AppEntity {
  const AppEntity({required this.metadata});

  final EntityMetadata metadata;
}

class User extends AppEntity {
  const User({
    required super.metadata,
    required this.displayName,
    required this.email,
  });

  final String displayName;
  final String email;
}

class Family extends AppEntity {
  const Family({
    required super.metadata,
    required this.name,
    required this.adultUserIds,
  });

  final String name;
  final List<String> adultUserIds;
}

class ChildProfile extends AppEntity {
  const ChildProfile({
    required super.metadata,
    required this.familyId,
    required this.displayName,
    required this.age,
  });

  final String familyId;
  final String displayName;
  final int age;
}

class TeenProfile extends AppEntity {
  const TeenProfile({
    required super.metadata,
    required this.familyId,
    required this.displayName,
    required this.age,
    this.privateReflectionEnabled = true,
  });

  final String familyId;
  final String displayName;
  final int age;
  final bool privateReflectionEnabled;
}

class AdultProfile extends AppEntity {
  const AdultProfile({
    required super.metadata,
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

class CaregiverRole extends AppEntity {
  const CaregiverRole({
    required super.metadata,
    required this.userId,
    required this.familyId,
    required this.label,
  });

  final String userId;
  final String familyId;
  final String label;
}

class ProfessionalRole extends AppEntity {
  const ProfessionalRole({
    required super.metadata,
    required this.userId,
    required this.familyId,
    required this.permissions,
  });

  final String userId;
  final String familyId;
  final List<String> permissions;
}

class Routine extends AppEntity {
  const Routine({
    required super.metadata,
    required this.profileId,
    required this.title,
    this.stepIds = const [],
    this.weekdays = const [],
    this.scheduledHour,
    this.scheduledMinute,
    this.estimatedDurationMinutes,
    this.leadReminderMinutes = 10,
    this.repeatPolicy = RoutineRepeatPolicy.weekly,
    this.responsibleAdultProfileId,
    this.contextLabel,
    this.minimumVersion,
    this.benefitDescription,
    this.maxReminderCount = 2,
    this.reminderIntervalMinutes = 5,
    this.vibrationEnabled = true,
    this.soundEnabled = false,
    this.silentNotification = false,
    this.canPostpone = true,
    this.canRequestHelp = true,
  });

  final String profileId;
  final String title;
  final List<String> stepIds;
  final List<int> weekdays;
  final int? scheduledHour;
  final int? scheduledMinute;
  final int? estimatedDurationMinutes;
  final int leadReminderMinutes;
  final RoutineRepeatPolicy repeatPolicy;
  final String? responsibleAdultProfileId;
  final String? contextLabel;
  final String? minimumVersion;
  final String? benefitDescription;
  final int maxReminderCount;
  final int reminderIntervalMinutes;
  final bool vibrationEnabled;
  final bool soundEnabled;
  final bool silentNotification;
  final bool canPostpone;
  final bool canRequestHelp;

  String? get scheduledTimeLabel {
    final hour = scheduledHour;
    final minute = scheduledMinute;
    if (hour == null || minute == null) {
      return null;
    }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  bool get hasSchedule => scheduledHour != null && scheduledMinute != null;
}

class RoutineStep extends AppEntity {
  const RoutineStep({
    required super.metadata,
    required this.routineId,
    required this.title,
    required this.order,
    this.estimatedMinutes,
    this.status = RoutineStepStatus.pending,
  });

  final String routineId;
  final String title;
  final int order;
  final int? estimatedMinutes;
  final RoutineStepStatus status;
}

class Habit extends AppEntity {
  const Habit({
    required super.metadata,
    required this.profileId,
    required this.title,
    required this.status,
    this.minimumVersion,
  });

  final String profileId;
  final String title;
  final HabitStatus status;
  final String? minimumVersion;
}

class HabitActivation extends AppEntity {
  const HabitActivation({
    required super.metadata,
    required this.habitId,
    required this.startedAt,
    this.confirmedOverride = false,
  });

  final String habitId;
  final DateTime startedAt;
  final bool confirmedOverride;
}

class ScheduleItem extends AppEntity {
  const ScheduleItem({
    required super.metadata,
    required this.profileId,
    required this.title,
    this.startsAt,
  });

  final String profileId;
  final String title;
  final DateTime? startsAt;
}

class VisualChoiceBoard extends AppEntity {
  const VisualChoiceBoard({
    required super.metadata,
    required this.profileId,
    required this.title,
    required this.options,
  });

  final String profileId;
  final String title;
  final List<String> options;
}

class EmotionCheckIn extends AppEntity {
  const EmotionCheckIn({
    required super.metadata,
    required this.profileId,
    this.emotion,
    this.energyLevel,
  });

  final String profileId;
  final String? emotion;
  final int? energyLevel;
}

class SupportRequest extends AppEntity {
  const SupportRequest({
    required super.metadata,
    required this.profileId,
    required this.kind,
    this.note,
  });

  final String profileId;
  final String kind;
  final String? note;
}

class TimeBankBenefit extends AppEntity {
  const TimeBankBenefit({
    required super.metadata,
    required this.profileId,
    required this.description,
    required this.minutesEarned,
    this.routineId,
    this.habitId,
    this.kind = BenefitKind.digitalTime,
    this.minutesUsed = 0,
    this.dailyLimitMinutes,
    this.expiresAt,
    this.accumulationAllowed = true,
    this.status = BenefitStatus.available,
    this.sourceAction,
    this.idempotencyKey,
    this.approvedByAdultId,
  });

  final String profileId;
  final String? routineId;
  final String? habitId;
  final BenefitKind kind;
  final String description;
  final int minutesEarned;
  final int minutesUsed;
  final int? dailyLimitMinutes;
  final DateTime? expiresAt;
  final bool accumulationAllowed;
  final BenefitStatus status;
  final String? sourceAction;
  final String? idempotencyKey;
  final String? approvedByAdultId;

  int get balanceMinutes => minutesEarned - minutesUsed;

  bool get hasBalance =>
      balanceMinutes > 0 && status == BenefitStatus.available;

  TimeBankBenefit copyWith({
    int? minutesUsed,
    BenefitStatus? status,
    String? approvedByAdultId,
  }) {
    return TimeBankBenefit(
      metadata: metadata,
      profileId: profileId,
      routineId: routineId,
      habitId: habitId,
      kind: kind,
      description: description,
      minutesEarned: minutesEarned,
      minutesUsed: minutesUsed ?? this.minutesUsed,
      dailyLimitMinutes: dailyLimitMinutes,
      expiresAt: expiresAt,
      accumulationAllowed: accumulationAllowed,
      status: status ?? this.status,
      sourceAction: sourceAction,
      idempotencyKey: idempotencyKey,
      approvedByAdultId: approvedByAdultId ?? this.approvedByAdultId,
    );
  }
}

class TimeBankSummary {
  const TimeBankSummary({
    required this.profileId,
    required this.availableMinutes,
    required this.usedMinutes,
    required this.benefits,
  });

  final String profileId;
  final int availableMinutes;
  final int usedMinutes;
  final List<TimeBankBenefit> benefits;
}

class Reward extends AppEntity {
  const Reward(
      {required super.metadata, required this.familyId, required this.title});

  final String familyId;
  final String title;
}

class Story extends AppEntity {
  const Story({
    required super.metadata,
    required this.title,
    required this.ageRange,
    required this.value,
    required this.body,
  });

  final String title;
  final String ageRange;
  final String value;
  final String body;
}

class StoryProgress extends AppEntity {
  const StoryProgress({
    required super.metadata,
    required this.storyId,
    required this.profileId,
    this.isFavorite = false,
  });

  final String storyId;
  final String profileId;
  final bool isFavorite;
}

class NotificationPreference extends AppEntity {
  const NotificationPreference({
    required super.metadata,
    required this.profileId,
    required this.intensity,
  });

  final String profileId;
  final String intensity;
}

class Device extends AppEntity {
  const Device(
      {required super.metadata, required this.userId, required this.platform});

  final String userId;
  final String platform;
}

class WearableConnection extends AppEntity {
  const WearableConnection({
    required super.metadata,
    required this.deviceId,
    required this.platform,
    this.enabled = false,
  });

  final String deviceId;
  final String platform;
  final bool enabled;
}

class ConsentRecord extends AppEntity {
  const ConsentRecord({
    required super.metadata,
    required this.familyId,
    required this.consentType,
    required this.grantedAt,
  });

  final String familyId;
  final String consentType;
  final DateTime grantedAt;
}

class AuditLog extends AppEntity {
  const AuditLog({
    required super.metadata,
    required this.actorId,
    required this.action,
    required this.targetType,
  });

  final String actorId;
  final String action;
  final String targetType;
}
