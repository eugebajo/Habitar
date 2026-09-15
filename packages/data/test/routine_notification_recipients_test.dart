// Reimplementación en Dart, puro y sin red, de la lógica de
// resolve_routine_notification_recipients (supabase/migrations/
// 0015_device_tokens.sql) contra los dobles en memoria ya existentes
// (InMemoryFamilyRepository, InMemoryDeviceTokenRepository,
// InMemoryPushNotificationPreferenceRepository) - mismo espíritu que el
// doble en memoria del bug HABITAR_ROUTINE_SAVE_23505
// (supabase_routine_completion_test.dart), con una diferencia importante
// que hay que decir explícita: ese archivo exercita el código REAL de
// SupabaseRoutineSessionRepository contra un servidor HTTP falso. Acá no
// hay ningún repositorio Flutter que llame a
// resolve_routine_notification_recipients - Y NO DEBE HABERLO, esa RPC
// tiene el EXECUTE revocado a todo salvo service_role a propósito (ver el
// comentario de seguridad en la migración): solo la Edge Function la
// llama. Por eso esto es una reimplementación de las mismas reglas de
// negocio, no un ejercicio del código de producción - prueba que estas
// reglas, escritas dos veces (SQL y Dart), coinciden en su intención; no
// reemplaza la verificación manual contra Postgres real que ya pide el
// propio archivo de la migración.

import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('resolveRoutineNotificationRecipients (doble en memoria)', () {
    late InMemoryFamilyRepository familyRepository;
    late InMemoryDeviceTokenRepository deviceTokenRepository;
    late InMemoryPushNotificationPreferenceRepository preferenceRepository;

    setUp(() {
      familyRepository = InMemoryFamilyRepository();
      deviceTokenRepository = InMemoryDeviceTokenRepository();
      preferenceRepository = InMemoryPushNotificationPreferenceRepository();
    });

    Future<(User, User, String)> twoAdultFamily() async {
      final authRepository = InMemoryAuthRepository();
      final owner = await authRepository.registerAdult(
        displayName: 'Dueña',
        email: 'duena@example.com',
        password: 'secret123',
      );
      final family = await familyRepository.createFamily(
        ownerUserId: owner.metadata.id,
        name: 'Familia con dos adultos',
      );
      final created = await familyRepository.createInvitationWithCode(
        familyId: family.metadata.id,
        email: 'otro@example.com',
        role: FamilyMemberRole.parent,
        invitedByUserId: owner.metadata.id,
        invitedByUserEmail: owner.email,
      );
      final other = await authRepository.registerAdult(
        displayName: 'Otro Adulto',
        email: 'otro@example.com',
        password: 'secret123',
      );
      await familyRepository.acceptInvitationByCode(
        code: created.code,
        userId: other.metadata.id,
        userEmail: other.email,
      );
      return (owner, other, family.metadata.id);
    }

    FamilyActivityEvent buildEvent({
      required String familyId,
      String? createdBy,
    }) {
      final now = DateTime.now();
      return FamilyActivityEvent(
        metadata: EntityMetadata(
          id: 'event-1',
          createdAt: now,
          updatedAt: now,
          ownerId: createdBy ?? familyId,
        ),
        familyId: familyId,
        profileId: 'profile-1',
        kind: 'routine_completed',
        profileDisplayName: 'Nico',
        routineTitle: 'Rutina de la tarde',
        createdBy: createdBy,
      );
    }

    test('excluye a quien originó el evento, no a los demás', () async {
      final (owner, other, familyId) = await twoAdultFamily();
      await deviceTokenRepository.registerToken(
          userId: owner.metadata.id, token: 'token-owner', platform: 'android');
      await deviceTokenRepository.registerToken(
          userId: other.metadata.id, token: 'token-other', platform: 'android');

      final recipients = await resolveRoutineNotificationRecipients(
        event: buildEvent(familyId: familyId, createdBy: owner.metadata.id),
        familyRepository: familyRepository,
        deviceTokenRepository: deviceTokenRepository,
        preferenceRepository: preferenceRepository,
        now: DateTime(2026, 1, 1, 12),
      );

      expect(recipients.map((t) => t.token), ['token-other']);
    });

    test('created_by null no excluye a nadie (IS DISTINCT FROM, no <>)',
        () async {
      final (owner, other, familyId) = await twoAdultFamily();
      await deviceTokenRepository.registerToken(
          userId: owner.metadata.id, token: 'token-owner', platform: 'android');
      await deviceTokenRepository.registerToken(
          userId: other.metadata.id, token: 'token-other', platform: 'android');

      final recipients = await resolveRoutineNotificationRecipients(
        event: buildEvent(familyId: familyId, createdBy: null),
        familyRepository: familyRepository,
        deviceTokenRepository: deviceTokenRepository,
        preferenceRepository: preferenceRepository,
        now: DateTime(2026, 1, 1, 12),
      );

      expect(
        recipients.map((t) => t.token).toSet(),
        {'token-owner', 'token-other'},
      );
    });

    test('un adulto de otra familia nunca aparece', () async {
      final (owner, other, familyId) = await twoAdultFamily();
      await deviceTokenRepository.registerToken(
          userId: other.metadata.id, token: 'token-other', platform: 'android');

      final otherFamilyAuth = InMemoryAuthRepository();
      final strangerAdult = await otherFamilyAuth.registerAdult(
        displayName: 'De otra familia',
        email: 'lejos@example.com',
        password: 'secret123',
      );
      await familyRepository.createFamily(
        ownerUserId: strangerAdult.metadata.id,
        name: 'Otra familia, sin relación',
      );
      await deviceTokenRepository.registerToken(
        userId: strangerAdult.metadata.id,
        token: 'token-stranger',
        platform: 'android',
      );

      final recipients = await resolveRoutineNotificationRecipients(
        event: buildEvent(familyId: familyId, createdBy: owner.metadata.id),
        familyRepository: familyRepository,
        deviceTokenRepository: deviceTokenRepository,
        preferenceRepository: preferenceRepository,
        now: DateTime(2026, 1, 1, 12),
      );

      expect(recipients.map((t) => t.token), ['token-other']);
    });

    test('push_enabled = false excluye al adulto', () async {
      final (owner, other, familyId) = await twoAdultFamily();
      await deviceTokenRepository.registerToken(
          userId: other.metadata.id, token: 'token-other', platform: 'android');
      await preferenceRepository.save(PushNotificationPreference(
        userId: other.metadata.id,
        pushEnabled: false,
      ));

      final recipients = await resolveRoutineNotificationRecipients(
        event: buildEvent(familyId: familyId, createdBy: owner.metadata.id),
        familyRepository: familyRepository,
        deviceTokenRepository: deviceTokenRepository,
        preferenceRepository: preferenceRepository,
        now: DateTime(2026, 1, 1, 12),
      );

      expect(recipients, isEmpty);
    });

    test('sin fila de preferencias, default push_enabled = true', () async {
      final (owner, other, familyId) = await twoAdultFamily();
      await deviceTokenRepository.registerToken(
          userId: other.metadata.id, token: 'token-other', platform: 'android');
      // Nunca se llamó a preferenceRepository.save para 'other'.

      final recipients = await resolveRoutineNotificationRecipients(
        event: buildEvent(familyId: familyId, createdBy: owner.metadata.id),
        familyRepository: familyRepository,
        deviceTokenRepository: deviceTokenRepository,
        preferenceRepository: preferenceRepository,
        now: DateTime(2026, 1, 1, 12),
      );

      expect(recipients.map((t) => t.token), ['token-other']);
    });

    test('horario silencioso normal (13:00-14:00) excluye adentro, no afuera',
        () async {
      final (owner, other, familyId) = await twoAdultFamily();
      await deviceTokenRepository.registerToken(
          userId: other.metadata.id, token: 'token-other', platform: 'android');
      await preferenceRepository.save(PushNotificationPreference(
        userId: other.metadata.id,
        pushEnabled: true,
        quietHoursStartHour: 13,
        quietHoursStartMinute: 0,
        quietHoursEndHour: 14,
        quietHoursEndMinute: 0,
      ));

      final inside = await resolveRoutineNotificationRecipients(
        event: buildEvent(familyId: familyId, createdBy: owner.metadata.id),
        familyRepository: familyRepository,
        deviceTokenRepository: deviceTokenRepository,
        preferenceRepository: preferenceRepository,
        now: DateTime(2026, 1, 1, 13, 30),
      );
      final outside = await resolveRoutineNotificationRecipients(
        event: buildEvent(familyId: familyId, createdBy: owner.metadata.id),
        familyRepository: familyRepository,
        deviceTokenRepository: deviceTokenRepository,
        preferenceRepository: preferenceRepository,
        now: DateTime(2026, 1, 1, 15, 0),
      );

      expect(inside, isEmpty);
      expect(outside.map((t) => t.token), ['token-other']);
    });

    test('horario silencioso que cruza medianoche (22:00-07:00)', () async {
      final (owner, other, familyId) = await twoAdultFamily();
      await deviceTokenRepository.registerToken(
          userId: other.metadata.id, token: 'token-other', platform: 'android');
      await preferenceRepository.save(PushNotificationPreference(
        userId: other.metadata.id,
        pushEnabled: true,
        quietHoursStartHour: 22,
        quietHoursStartMinute: 0,
        quietHoursEndHour: 7,
        quietHoursEndMinute: 0,
      ));

      final lateNight = await resolveRoutineNotificationRecipients(
        event: buildEvent(familyId: familyId, createdBy: owner.metadata.id),
        familyRepository: familyRepository,
        deviceTokenRepository: deviceTokenRepository,
        preferenceRepository: preferenceRepository,
        now: DateTime(2026, 1, 1, 23, 30),
      );
      final earlyMorning = await resolveRoutineNotificationRecipients(
        event: buildEvent(familyId: familyId, createdBy: owner.metadata.id),
        familyRepository: familyRepository,
        deviceTokenRepository: deviceTokenRepository,
        preferenceRepository: preferenceRepository,
        now: DateTime(2026, 1, 2, 5, 0),
      );
      final midday = await resolveRoutineNotificationRecipients(
        event: buildEvent(familyId: familyId, createdBy: owner.metadata.id),
        familyRepository: familyRepository,
        deviceTokenRepository: deviceTokenRepository,
        preferenceRepository: preferenceRepository,
        now: DateTime(2026, 1, 1, 12, 0),
      );

      expect(lateNight, isEmpty);
      expect(earlyMorning, isEmpty);
      expect(midday.map((t) => t.token), ['token-other']);
    });
  });
}

/// La reimplementación en sí - ver el comentario al inicio del archivo
/// sobre qué prueba y qué no. Deliberadamente vive en el test, no en
/// lib/: no es código de producción, nadie más la llama.
Future<List<DeviceToken>> resolveRoutineNotificationRecipients({
  required FamilyActivityEvent event,
  required InMemoryFamilyRepository familyRepository,
  required InMemoryDeviceTokenRepository deviceTokenRepository,
  required InMemoryPushNotificationPreferenceRepository preferenceRepository,
  required DateTime now,
}) async {
  final members = await familyRepository.membersForFamily(event.familyId);
  final recipients = <DeviceToken>[];
  for (final member in members) {
    // == alcanza para el mismo comportamiento que "IS DISTINCT FROM" de
    // SQL: si event.createdBy es null, la comparación contra un
    // member.userId (String, nunca null) siempre da false, así que nunca
    // se excluye a nadie - igual que en la migración.
    if (member.userId == event.createdBy) continue;

    final preference = await preferenceRepository.forUser(member.userId);
    final pushEnabled = preference?.pushEnabled ?? true;
    if (!pushEnabled) continue;

    if (preference != null &&
        preference.hasQuietHours &&
        _isWithinQuietHours(now, preference)) {
      continue;
    }

    recipients.addAll(deviceTokenRepository.tokensForUser(member.userId));
  }
  return recipients;
}

bool _isWithinQuietHours(DateTime now, PushNotificationPreference preference) {
  final nowMinutes = now.hour * 60 + now.minute;
  final startMinutes = preference.quietHoursStartHour! * 60 +
      preference.quietHoursStartMinute!;
  final endMinutes =
      preference.quietHoursEndHour! * 60 + preference.quietHoursEndMinute!;
  if (startMinutes <= endMinutes) {
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }
  return nowMinutes >= startMinutes || nowMinutes < endMinutes;
}
