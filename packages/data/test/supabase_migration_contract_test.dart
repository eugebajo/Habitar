import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String migration0003;
  late final String migration0004;
  late final String migration0005;
  late final String migration0006;

  setUpAll(() {
    migration0003 = File(
      'supabase/migrations/0003_time_bank_benefits.sql',
    ).readAsStringSync();
    migration0004 = File(
      'supabase/migrations/0004_family_invitations_and_routine_overrides.sql',
    ).readAsStringSync();
    migration0005 = File(
      'supabase/migrations/0005_initial_family_bootstrap.sql',
    ).readAsStringSync();
    migration0006 = File(
      'supabase/migrations/0006_pending_family_invitations.sql',
    ).readAsStringSync();
  });

  test('protects time bank benefits with family-scoped RLS', () {
    expect(
      migration0003,
      contains('alter table public.time_bank_benefits enable row level security'),
    );
    expect(
      migration0003,
      contains('family_members.family_id = profiles.family_id'),
    );
    expect(
      migration0003,
      contains('profiles.id = time_bank_benefits.profile_id'),
    );
    expect(migration0003, contains('family_members.user_id = auth.uid()'));
    expect(migration0003, contains('to authenticated'));
    expect(migration0003, isNot(contains('using (true)')));
    expect(migration0003, isNot(contains('with check (true)')));
  });

  test('uses expected foreign keys for time bank benefits', () {
    expect(
      migration0003,
      contains('profile_id uuid not null references public.profiles(id)'),
    );
    expect(
      migration0003,
      contains('routine_id uuid references public.routines(id)'),
    );
    expect(
      migration0003,
      contains('habit_id uuid references public.habits(id)'),
    );
    expect(
      migration0003,
      contains('approved_by_adult_id uuid references auth.users(id)'),
    );
    expect(migration0003, contains('routines_id_profile_id_idx'));
    expect(migration0003, contains('habits_id_profile_id_idx'));
    expect(
      migration0003,
      contains('constraint time_bank_benefits_routine_profile_fk'),
    );
    expect(
      migration0003,
      contains('foreign key (routine_id, profile_id)'),
    );
    expect(
      migration0003,
      contains('references public.routines(id, profile_id)'),
    );
    expect(
      migration0003,
      contains('constraint time_bank_benefits_habit_profile_fk'),
    );
    expect(migration0003, contains('foreign key (habit_id, profile_id)'));
    expect(
      migration0003,
      contains('references public.habits(id, profile_id)'),
    );
  });

  test('limits time bank benefit writes to authorized adults', () {
    expect(
      migration0003,
      contains("family_members.role in ('owner', 'parent', 'caregiver')"),
    );
    expect(
      migration0003,
      isNot(contains(
        "family_members.role in ('owner', 'parent', 'caregiver', "
        "'professional', 'viewer')",
      )),
    );
    expect(migration0003, contains('for select'));
    expect(migration0003, contains('for insert'));
    expect(migration0003, contains('for update'));
    expect(migration0003, contains('for delete'));
  });

  test('prevents unsafe time bank benefit writes', () {
    expect(
      migration0003,
      contains(
        'approved_by_adult_id is null or approved_by_adult_id = auth.uid()',
      ),
    );
    expect(
      migration0003,
      contains('owner_id is null or owner_id = auth.uid()'),
    );
    expect(
      migration0003,
      contains('check (minutes_used >= 0 and minutes_used <= minutes_earned)'),
    );
    expect(
      migration0003,
      contains('daily_limit_minutes is null or daily_limit_minutes > 0'),
    );
  });

  test('keeps time bank access scoped to the profile family', () {
    expect(
      migration0003,
      contains('where profiles.id = time_bank_benefits.profile_id'),
    );
    expect(
      migration0003,
      contains('join public.family_members on family_members.family_id = '
          'profiles.family_id'),
    );
    expect(migration0003, contains('family_members.user_id = auth.uid()'));
    expect(migration0003, isNot(contains('using (owner_id = auth.uid())')));
    expect(
      migration0003,
      isNot(contains('using (\n  owner_id = auth.uid()')),
    );
  });

  test('does not grant write access to viewer or professional roles', () {
    final writePolicyStart =
        migration0003.indexOf('authorized adults can insert time bank benefits');
    final writePolicyEnd =
        migration0003.indexOf('create policy "authorized adults can delete');
    final writePolicies =
        migration0003.substring(writePolicyStart, writePolicyEnd);

    expect(writePolicies, contains("'owner', 'parent', 'caregiver'"));
    expect(writePolicies, isNot(contains("'viewer'")));
    expect(writePolicies, isNot(contains("'professional'")));
  });

  test('expires invitations without rolling back the status update', () {
    expect(migration0004, contains("set status = 'expired'"));
    expect(migration0004, contains("'status', 'expired'"));
    expect(
      migration0004,
      isNot(contains("raise exception 'INVITATION_EXPIRED'")),
    );
  });

  test('uses hardened security definer RPCs for invite accept and revoke', () {
    expect(migration0004, contains('function public.accept_family_invitation'));
    expect(migration0004, contains('function public.revoke_family_invitation'));
    expect(migration0004, contains("security definer\nset search_path = ''"));
    expect(migration0004, contains('revoke all on function'));
    expect(migration0004, contains("set status = 'revoked'"));
    expect(migration0004, contains("invitation_row.status <> 'pending'"));
  });

  test('does not use destructive table or mass delete operations', () {
    final migrations = '${migration0003.toLowerCase()}\n'
        '${migration0004.toLowerCase()}\n'
        '${migration0005.toLowerCase()}\n'
        '${migration0006.toLowerCase()}';
    expect(migrations, isNot(contains('drop table')));
    expect(migrations, isNot(contains('delete from')));
    expect(migrations, isNot(contains('truncate')));
  });

  test('creates a hardened initial family bootstrap RPC', () {
    final signature = RegExp(
      r'create\s+or\s+replace\s+function\s+public\.create_initial_family\s*'
      r'\(([^)]*)\)',
      caseSensitive: false,
    ).firstMatch(migration0005)?.group(1);

    expect(signature, isNotNull);
    expect(signature!.trim().toLowerCase(), 'family_name text');
    expect(signature, isNot(contains('user_id')));
    expect(signature, isNot(contains('owner')));
    expect(signature, isNot(contains('adult')));
    expect(
      migration0005,
      contains('function public.create_initial_family(family_name text)'),
    );
    expect(migration0005, contains('security definer'));
    expect(migration0005, contains("set search_path = ''"));
    expect(migration0005, contains('current_user_id := auth.uid()'));
    expect(migration0005, contains('current_user_id is null'));
    expect(migration0005, contains('FAMILY_NAME_REQUIRED'));
    expect(migration0005, contains('FAMILY_NAME_TOO_LONG'));
    expect(migration0005, contains('pg_advisory_xact_lock'));
    expect(migration0005.toLowerCase(), isNot(contains('service_role')));
  });

  test('bootstraps family and owner membership atomically from auth uid', () {
    expect(
      migration0005,
      contains('insert into public.families (owner, name)'),
    );
    expect(
      migration0005,
      contains('values (current_user_id, normalized_name)'),
    );
    expect(
      migration0005,
      contains('insert into public.family_members (family_id, user_id, role)'),
    );
    expect(
      migration0005,
      contains("values (family_row.id, current_user_id, 'owner')"),
    );
    expect(migration0005, contains('on conflict (family_id, user_id)'));
    expect(migration0005, contains('return family_row'));
  });

  test('limits initial family bootstrap execute permissions', () {
    expect(
      migration0005,
      contains('revoke all on function public.create_initial_family(text)'),
    );
    expect(migration0005, contains('from public'));
    expect(migration0005, contains('from anon'));
    expect(
      migration0005,
      contains('grant execute on function public.create_initial_family(text)'),
    );
    expect(migration0005, contains('to authenticated'));
    expect(migration0005, isNot(contains('using (true)')));
    expect(migration0005, isNot(contains('with check (true)')));
  });

  test('lists pending invitations only for the authenticated email', () {
    expect(
      migration0006,
      contains(
        'function public.pending_family_invitations_for_current_user()',
      ),
    );
    expect(migration0006, contains('security definer'));
    expect(migration0006, contains("set search_path = ''"));
    expect(migration0006, contains('auth.uid() is not null'));
    expect(migration0006, contains("auth.jwt() ->> 'email'"));
    expect(migration0006, contains("adult_invitations.status = 'pending'"));
    expect(migration0006, contains('adult_invitations.expires_at > now()'));
    expect(migration0006, contains('families.name as family_name'));
    expect(
      migration0006,
      contains(
        'grant execute on function public.pending_family_invitations_for_current_user()',
      ),
    );
    expect(migration0006, contains('to authenticated'));
    expect(migration0006.toLowerCase(), isNot(contains('service_role')));
    final signature = RegExp(
      r'create\s+or\s+replace\s+function\s+public\.pending_family_invitations_for_current_user\s*'
      r'\(([^)]*)\)',
      caseSensitive: false,
    ).firstMatch(migration0006)?.group(1);
    expect(signature, isNotNull);
    expect(signature!.trim(), isEmpty);
  });
}
