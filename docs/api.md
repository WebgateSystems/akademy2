# API (Swagger / OpenAPI)

Kontrakt API jest generowany przez `rswag` i wersjonowany w repo:

- plik: [`docs/swagger/v1/swagger.yaml`](swagger/v1/swagger.yaml)
- UI: `/api-docs/index.html` (w dev po uruchomieniu aplikacji)

## Autoryzacja (Swagger)

Swagger opisuje, żeby:

1. wykonać `POST /api/v1/session` (logowanie) i odebrać `access_token`
2. wkleić token w „Authorize” jako nagłówek:

`Authorization: Bearer <access_token>`

Uwaga: część kontrolerów API w tym repo obsługuje również **sesję Devise (cookies)** (żeby panel WWW mógł wołać JSON bez osobnego JWT).

## Najważniejsze grupy endpointów (skrót)

Pełna lista jest w Swaggerze, ale w praktyce najczęściej dotykane obszary to:

- **Session**
  - `POST /api/v1/session`
- **Rejestracja (API)**
  - `GET /api/v1/register/flow`
  - `POST /api/v1/register/profile`
  - `POST /api/v1/register/verify_phone`
  - `POST /api/v1/register/set_pin`
  - `POST /api/v1/register/confirm_pin`
  - `POST /api/v1/register/student`
  - `POST /api/v1/register/teacher`
- **Uczeń**
  - join do klasy: `POST /api/v1/student/enrollments/join`
  - quiz results: `GET/POST /api/v1/student/quiz_results`
  - telemetria: `POST /api/v1/student/events` + `/batch`
  - wideo szkolne: `/api/v1/student/videos/*`
- **Nauczyciel**
  - join do szkoły: `POST /api/v1/teacher/school_enrollments/join`
  - moderacja wideo: `/api/v1/teacher/videos/*`
- **Zarządzanie szkołą (principal/school_manager)**
  - `/api/v1/management/*` (teachers/students/classes/academic_years/parents)
  - zatwierdzanie uczniów: `POST /api/v1/management/students/:id/approve`
- **Treści edukacyjne**
  - `GET /api/v1/subjects` + `/with_contents`
  - `GET /api/v1/subjects/:id`
  - `GET /api/v1/units`, `GET /api/v1/learning_modules`, `GET /api/v1/contents`
- **Certyfikaty**
  - `GET /api/v1/certificates/:id`
  - `GET /api/v1/certificates/:id/download`

Powiązane: standardowe ścieżki użytkowników (które endpointy wchodzą w grę) są opisane w [`docs/flow_uzytkownikow.md`](flow_uzytkownikow.md).

## Regenerowanie Swaggera

```bash
bundle exec rake rswag:specs:swaggerize
```


