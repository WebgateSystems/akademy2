# Założenia projektu (skrót) + mapowanie na repo

Ten dokument opisuje najważniejsze założenia i wymagania (role, treści edukacyjne, quiz/certyfikaty, offline, telemetria, bezpieczeństwo) **w formie Markdown** i mapuje je na aktualny kod w tym repo.

## Role (wymagania → implementacja)

Wymagane role:

- **Admin aplikacji** / **Manager** (globalny dostęp)
- **Dyrektor** / **Manager szkolny**
- **Nauczyciel**
- **Uczeń**
- **Rodzic** (flow może być pominięty)

Aktualne role w kodzie (seed w `db/seeds/development/000_roles.rb`):

- `admin`, `manager`, `principal`, `school_manager`, `teacher`, `student`, `parent`

Powiązane panele WWW:

- **Superadmin**: `/admin` (namespace `Admin`)
- **Zarządzanie szkołą**: `/management` (namespace `Management`) – dla `principal`/`school_manager`
- **Panel nauczyciela**: `/dashboard`
- **Panel ucznia**: `/home`

Szczegóły flow: [`docs/flow_uzytkownikow.md`](flow_uzytkownikow.md)

## Struktura treści edukacyjnych (Subject → Unit → LearningModule → Content)

Wymaganie: tematy → moduły → materiały (wideo+napisy → infografika → quiz), w przyszłości więcej.

W repo:

- modele i relacje są opisane w: [`docs/architecture_learning_modules.md`](architecture_learning_modules.md)
- diagramy: [`docs/learning_modules_diagram.md`](learning_modules_diagram.md)
- wizualny ERD (PNG): [`docs/relations.png`](relations.png)

## Quiz i certyfikat

Wymaganie: quiz + certyfikat PDF po zaliczeniu (próg ≥ 80%).

W repo:

- próg zaliczenia jest traktowany jako **80%** (np. `StudentDashboardController`, API `Student::QuizResultsController`)
- generowanie PDF: `CertificatePdf` (Prawn + szablon PDF w `app/assets/images/certificates/`)
- tworzenie rekordu certyfikatu: `Api::V1::Certificates::Create`

Uwaga: obecnie endpointy `GET /api/v1/certificates/:id` i `GET /api/v1/certificates/:id/download` **nie mają wymuszonej autoryzacji** (to może być celowe dla weryfikacji/udostępniania, ale warto świadomie potwierdzić).

## Offline / mobilka

Założenia zakładają tryb offline w aplikacji mobilnej (pobieranie treści + późniejsza dostępność).

W repo jest endpoint `GET /api/v1/subjects/with_contents` (Swagger: [`docs/swagger/v1/swagger.yaml`](swagger/v1/swagger.yaml)), który jest naturalnym „punktem startowym” do pobierania struktury treści.

## WCAG 2.1 AA / bezpieczeństwo

Założenia kładą nacisk m.in. na:

- **WCAG 2.1 AA** (kontrast, focus, napisy, obsługa klawiaturą)
- **HTTPS**, nagłówki bezpieczeństwa
- **RBAC** (role/uprawnienia)
- telemetria zdarzeń

W repo:

- role/uprawnienia są oparte o `roles` + policy Pundit (np. `SchoolManagementPolicy`)
- telemetria jest realizowana przez `EventLogger` + API student events (`/api/v1/student/events`)


