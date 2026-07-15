# Seguridad y privacidad

## Implementado en Fase 1

- Separacion por familia en la migracion Supabase.
- Row Level Security habilitado en tablas iniciales.
- Perfiles infantiles sin email obligatorio.
- `.env.example` sin secretos reales.
- Auditoria inicial para acciones sensibles.

## Pendiente antes de produccion

- Revision legal COPPA/GDPR/GDPR-K.
- Borrado de cuenta y exportacion de datos.
- Rate limiting en Edge Functions.
- Politica de privacidad provisional revisada.
- Logs sin contenido sensible en cliente y servidor.
- Cifrado y consentimiento especifico si se habilitan audios familiares.
