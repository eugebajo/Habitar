# Habitar - Activación de Supabase

Supabase queda integrado en dos niveles.

## Ya implementado

- Web puede usar Supabase Auth cuando el build recibe `SUPABASE_URL` y
  `SUPABASE_ANON_KEY`.
- Android/iOS pueden usar Supabase Auth cuando el build recibe los mismos
  `dart-define`.
- Web conserva datos familiares localmente en el navegador con `localStorage`.
- Android/iOS conservan datos familiares localmente con SQLite/Drift.

## Importante

La activación actual conecta autenticación remota.

Todavía falta implementar repositorios Supabase para sincronizar estos datos
entre web, Android e iOS:

- Familias.
- Perfiles.
- Rutinas.
- Pasos de rutina.
- Hábitos.
- Progreso.
- Check-ins de bienestar.

Hasta completar esos repositorios, una persona puede autenticarse con Supabase,
pero sus rutinas/perfiles se guardan localmente en cada dispositivo.

## Configurar GitHub Pages

Ir al repositorio en GitHub:

```text
https://github.com/eugebajo/Habitar
```

Luego:

1. Entrar a **Settings**.
2. Ir a **Secrets and variables**.
3. Entrar a **Actions**.
4. Abrir la pestaña **Variables**.
5. Crear variable:

```text
SUPABASE_URL
```

Valor:

```text
https://frmgwpbstezqjwbcshbw.supabase.co
```

6. Abrir la pestaña **Secrets**.
7. Crear secret:

```text
SUPABASE_ANON_KEY
```

Valor: usar la publishable key de Supabase.

8. Ir a **Actions**.
9. Abrir **Habitarpy Pages**.
10. Ejecutar **Run workflow**.

Cuando termine en verde, la app web estará compilada con Supabase Auth:

```text
https://habitarpy.com/app/
```

## Build Android con Supabase

En PowerShell, antes de construir:

```powershell
$env:SUPABASE_URL='https://frmgwpbstezqjwbcshbw.supabase.co'
$env:SUPABASE_ANON_KEY='TU_PUBLISHABLE_KEY'
.\scripts\android_build_release.ps1
```

El bundle saldrá en:

```text
apps/mobile/build/app/outputs/bundle/release/app-release.aab
```

## Cómo verificar

1. Abrir la app web o Android.
2. Crear una cuenta adulta con un email real de prueba.
3. Revisar en Supabase Dashboard:
   - **Authentication > Users**
4. Confirmar que el usuario aparece.

Si el usuario aparece, Supabase Auth está activo.

## Próxima fase técnica

Implementar repositorios remotos para:

1. `SupabaseFamilyRepository`
2. `SupabaseProfileRepository`
3. `SupabaseRoutineRepository`
4. `SupabaseHabitRepository`
5. `SupabaseWellbeingRepository`

Después de eso, web, Android e iOS podrán compartir los mismos datos familiares
con una misma cuenta.
