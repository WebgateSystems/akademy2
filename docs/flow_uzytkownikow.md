# Flow użytkowników (standardowe ścieżki)

Ten dokument opisuje **standardowe ścieżki** dla ról (od admina aplikacji do ucznia), bazując na:

- założeniach opisanych w [`docs/zalozenia_projektu.md`](zalozenia_projektu.md),
- realnych routach i kontrolerach w tym repo (`config/routes.rb`).

## Mapa paneli / wejść

- **Superadmin** (globalny): `/admin`
- **Zarządzanie szkołą** (dyrektor/manager szkolny): `/management`
- **Nauczyciel**: `/dashboard`
- **Uczeń**: `/home`

Logowanie (ładne aliasy do Devise):

- uczeń: `/login/student`
- nauczyciel: `/login/teacher`
- administracja szkoły: `/login/administration`

## 1) Superadmin (globalny)

Zakres (typowy):

- zarządzanie zasobami „globalnymi” (m.in. treści edukacyjne: `Subject/Unit/LearningModule/Content`)
- administracja platformy

Wejście:

- panel: **`/admin`** (namespace `Admin`)
- zasoby są obsługiwane generycznie przez `Admin::ResourcesController` (CRUD w `/admin/:resource`)

Powiązane: architektura treści jest opisana w [`docs/architecture_learning_modules.md`](architecture_learning_modules.md).

## 2) Dyrektor / Manager szkolny (`principal`, `school_manager`)

Wejście:

- panel: **`/management`**

Typowe ścieżki:

### 2.1 Przegląd szkoły + statystyki

- `/management` – dashboard szkoły (liczby uczniów/nauczycieli, informacje o dyrektorze/managerze)

### 2.2 Zarządzanie nauczycielami / uczniami / rodzicami

- `/management/teachers`
- `/management/students`
- `/management/parents`
- `/management/classes`
- `/management/years`

API (to samo, pod panel i/lub integracje):

- `/api/v1/management/teachers/*`
- `/api/v1/management/students/*` (w tym approve/decline)
- `/api/v1/management/classes/*`
- `/api/v1/management/academic_years/*`

## 3) Nauczyciel (`teacher`)

Wejście:

- panel: **`/dashboard`**

### 3.1 Dołączenie do szkoły (z linkiem/tokenem)

Scenariusz „z linkiem”:

1. nauczyciel otwiera link: `GET /join/school/:token`
2. jeśli nie jest zalogowany – trafia na rejestrację nauczyciela (`/register/teacher`) z przypiętym tokenem szkoły
3. po rejestracji konto jest tworzone i użytkownik trafia do `/dashboard` ze statusem „oczekuje na akceptację”

Po zalogowaniu, faktyczne „dołączenie” do szkoły jest realizowane przez API:

- `POST /api/v1/teacher/school_enrollments/join` z `token`
- status trafia jako `pending`, a szkoła (i rola nauczyciela w `user_roles`) dostaje `school_id`

### 3.2 Klasy + QR/link dla uczniów

W panelu nauczyciela:

- lista i wybór klasy: `/dashboard` (param `class_id`)
- lista uczniów: `/dashboard/students`
- wyniki quizów po przedmiocie: `/dashboard/quiz_results/:subject_id`
- moderacja wideo uczniów: `/dashboard/pupil_videos`

QR do dołączenia ucznia do klasy:

- `GET /dashboard/class_qr.svg?class_id=...` (generuje URL w formie `GET /join/class/:token`)
- `GET /dashboard/class_qr.png?class_id=...`

### 3.3 Akceptacja dołączenia ucznia do klasy

Gdy uczeń dołącza do klasy, tworzony jest `StudentClassEnrollment` ze statusem `pending`.

Nauczyciel (lub dyrektor/manager) zatwierdza:

- `POST /api/v1/management/students/:id/approve`

Ta akcja:

- ustawia status zapisu na `approved`,
- (jeśli trzeba) potwierdza konto ucznia (`confirmed_at`),
- rozwiązuje notyfikacje „awaiting approval”.

## 4) Uczeń (`student`)

Wejście:

- panel: **`/home`**

### 4.1 Rejestracja ucznia „bez linku” (bez tokenu klasy)

Ścieżka webowa (wizard):

- `/register/profile` → `/register/verify-phone` → `/register/set-pin` → `/register/set-pin-confirm` → `/register/confirm-email`

Po rejestracji uczeń może później dołączyć do klasy (patrz 4.2).

### 4.2 Dołączenie do klasy „z linkiem” (token klasy / join)

Scenariusz „z linkiem”:

1. uczeń otwiera link/QR: `GET /join/class/:token`
2. po zalogowaniu/rejestracji token jest przechowany w sesji i wizard przechodzi w tryb „student z tokenem”
3. po zakończeniu rejestracji uczeń trafia do `/home` z komunikatem o oczekiwaniu na akceptację

API do dołączenia do klasy (np. mobilka):

- `POST /api/v1/student/enrollments/join` z `token`
- status: `pending`

### 4.3 Nauka: Subject → Module → Content → Quiz → Result

Ścieżka webowa:

- lista przedmiotów: `GET /home`
- przedmiot: `GET /home/subjects/:id` (slug lub UUID); jeśli jest tylko 1 moduł → automatyczny redirect do modułu
- moduł: `GET /home/modules/:id` (treści poza quizem, krokowane parametrem `step`)
- quiz: `GET /home/modules/:id/quiz`
- submit quiz: `POST /home/modules/:id/quiz`
- wynik: `GET /home/modules/:id/result`

Wynik quizu:

- próg zaliczenia w UI/logice to **80%**
- zapis wyniku do `QuizResult`

### 4.4 Certyfikat PDF po quizie

Po zapisie wyniku, system tworzy (lub odświeża) certyfikat powiązany z `QuizResult` i generuje PDF.

API:

- `GET /api/v1/certificates/:id`
- `GET /api/v1/certificates/:id/download` (PDF)

Uwaga: obecnie te endpointy nie wymuszają autoryzacji – warto to traktować jako decyzję produktową (udostępnianie/weryfikacja) i świadomie potwierdzić.

### 4.5 Dodatkowe funkcje ucznia: wideo szkolne + notyfikacje

- wideo szkolne: `/home/videos` (upload i moderacja przez nauczyciela)
- notyfikacje: `/home/notifications`

API:

- `POST /api/v1/student/videos` + moderacja po stronie nauczyciela
- `POST /api/v1/student/events` oraz `POST /api/v1/student/events/batch` (telemetria)


