# Flowmati - Arquitectura del Sistema

## Overview
App SaaS móvil para generación automatizada de videos faceless virales.

## Componentes Principales

### Frontend (Emergent Labs)
- Onboarding flow
- Dashboard de videos
- Centro de IA (templates)
- Perfil de usuario
- Configuración

### Backend
- Autenticación de usuarios
- Base de datos (Users, Videos, Templates, Media)
- Sistema de suscripciones (Stripe)
- Rate limiting

### APIs Externas
- OpenAI/Claude: Generación de scripts
- ElevenLabs: Text-to-speech
- HeyGen: Video generation
- Stripe: Payments

### Templates Disponibles
1. Videos POV
2. Lectura de comentarios (Reddit/X)
3. Videos UGC
4. Videos de juegos con voz
5. Texto a video
6. Imagen a video

## Database Schema (Draft)
- Users (id, email, subscription_tier, created_at)
- Videos (id, user_id, template_type, status, url)
- Templates (id, name, type, config)
- Media (id, user_id, type, url)
