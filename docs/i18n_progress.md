# Postęp internacjonalizacji (I18n)

Ten dokument śledzi postęp prac nad internacjonalizacją aplikacji AKAdemy.

**Domyślny locale:** `pl` (polski)  
**Dostępne locales:** `pl`, `en`

**Status:** ✅ **ZAKOŃCZONE** - wszystkie widoki użytkownika przetłumaczone na język polski

---

## ✅ Zrobione

### Konfiguracja
- [x] `config/application.rb` - ustawiony `default_locale: :pl`
- [x] `config/locales/pl.yml` - dodane tłumaczenia dla nawigacji, dashboard, enter
- [x] `config/locales/devise.pl.yml` - tłumaczenia Devise

### Layouts
- [x] `app/views/layouts/enter.html.slim` - tytuł strony
- [x] `app/views/layouts/management.html.erb` - nawigacja boczna (Profil szkoły, Administracja, Nauczyciele, Uczniowie, Rodzice, Klasy, Lata)
- [x] `app/views/layouts/admin.html.slim` - nawigacja boczna (Szkoły, Dyrektorzy, Nauczyciele, Uczniowie, Dziennik aktywności, Przedmioty, Jednostki, Moduły, Treści)
- [x] `app/views/layouts/landing.html.slim` - strona landingowa

### Widoki - Enter (strona wyboru roli)
- [x] `app/views/enter/index.html.slim` - "Kim jesteś?", Uczeń, Nauczyciel, Administracja

### Widoki - Dashboard (nauczyciel)
- [x] `app/views/dashboard/index.html.slim` - hero section, statystyki, wyniki uczniów
- [x] `app/views/dashboard/quiz_results.html.slim` - nagłówki tabeli, eksport
- [x] `app/views/dashboard/_sidebar.html.slim` - nawigacja boczna, aria-labels
- [x] `app/views/dashboard/_top_bar.html.slim` - górny pasek, aria-labels
- [x] `app/views/dashboard/students.html.slim` - lista uczniów, statusy, modale zatwierdzenia/odrzucenia
- [x] `app/views/dashboard/show_student.html.slim` - szczegóły ucznia, wyniki z przedmiotów
- [x] `app/views/dashboard/notifications.html.slim` - lista powiadomień, filtry
- [x] `app/views/dashboard/student_videos.html.slim` - filmy uczniów, modale akcji
- [x] `app/views/dashboard/pending_school_enrollment.html.slim` - oczekiwanie na akceptację
- [x] `app/views/dashboard/no_school.html.slim` - brak szkoły, formularz dołączenia

### Widoki - Management (dyrekcja)
- [x] `app/views/management/_top_bar.html.erb` - tytuł, aria-labels
- [x] `app/views/management/teachers/index.html.erb` - lista nauczycieli, formularze, modale
- [x] `app/views/management/students/index.html.erb` - lista uczniów, formularze, modale
- [x] `app/views/management/administrations/index.html.slim` - lista administracji, formularze
- [x] `app/views/management/classes/index.html.erb` - lista klas, formularze
- [x] `app/views/management/years/index.html.erb` - lista lat szkolnych, formularze
- [x] `app/views/management/notifications/index.html.erb` - centrum powiadomień, filtry
- [x] `app/views/management/parents/index.html.slim` - lista rodziców, formularze, modale

### Widoki - Admin (globalny admin)
- [x] `app/views/admin/_top_bar.html.slim` - aria-labels
- [x] `app/views/admin/sessions/new.html.erb` - logowanie administratora
- [x] `app/views/admin/resources/schools.html.erb` - lista szkół, formularze
- [x] `app/views/admin/resources/headmasters.html.erb` - lista dyrektorów, formularze
- [x] `app/views/admin/resources/teachers.html.erb` - lista nauczycieli
- [x] `app/views/admin/resources/students.html.erb` - lista uczniów
- [x] `app/views/admin/resources/subjects.html.erb` - przedmioty
- [x] `app/views/admin/resources/units.html.erb` - jednostki
- [x] `app/views/admin/resources/learning_modules.html.erb` - moduły
- [x] `app/views/admin/resources/contents.html.erb` - treści
- [x] `app/views/admin/resources/activity_log.html.erb` - dziennik aktywności

### Widoki - Student (uczeń)
- [x] `app/views/student_dashboard/_sidebar.html.slim` - nawigacja boczna
- [x] `app/views/student_dashboard/_top_bar.html.slim` - górny pasek
- [x] `app/views/student_dashboard/index.html.slim` - strona główna ucznia
- [x] `app/views/student_dashboard/account.html.slim` - konto użytkownika
- [x] `app/views/student_dashboard/settings.html.slim` - ustawienia
- [x] `app/views/student_dashboard/notifications.html.slim` - powiadomienia
- [x] `app/views/student_dashboard/school_videos.html.slim` - filmy szkolne
- [x] `app/views/student_dashboard/quiz.html.slim` - quiz
- [x] `app/views/student_dashboard/result.html.slim` - wyniki
- [x] `app/views/student_dashboard/subject.html.slim` - przedmiot
- [x] `app/views/student_dashboard/learning_module.html.slim` - moduł
- [x] `app/views/student_dashboard/video_waiting.html.slim` - oczekiwanie
- [x] `app/views/home/index.html.erb` - strona główna

### Widoki - Devise (logowanie/rejestracja)
- [x] `app/views/devise/sessions/new.slim` - logowanie
- [x] `app/views/devise/passwords/new.slim` - resetowanie hasła
- [x] `app/views/devise/passwords/edit.slim` - ustawianie nowego hasła/PIN
- [x] `app/views/devise/shared/_links.slim` - linki nawigacyjne
- [x] `app/views/devise/shared/_error_messages.html.erb` - komunikaty błędów

### Widoki - Rejestracja
- [x] `app/views/register/wizard/student.slim` - formularz rejestracji ucznia
- [x] `app/views/register/wizard/teacher.slim` - formularz rejestracji nauczyciela
- [x] `app/views/register/wizard/profile.slim` - formularz uzupełniania profilu

### Widoki - Shared
- [x] `app/views/shared/_theme_toggle.html.slim` - przełącznik motywu
- [x] `app/views/shared/_app_version.html.slim` - wersja aplikacji

### Mailery Devise
- [x] `app/views/devise/mailer/reset_password_instructions.html.mjml`
- [x] `app/views/devise/mailer/confirmation_instructions.html.mjml`
- [x] `app/views/devise/mailer/email_changed.html.mjml`
- [x] `app/views/devise/mailer/password_change.html.mjml`
- [x] `app/views/devise/mailer/unlock_instructions.html.mjml`

### Testy
- [x] `spec/requests/student_dashboard_spec.rb` - naprawione asercje dla polskich tekstów

---

## ❌ Do zrobienia

*(Wszystkie główne widoki zostały przetłumaczone)*

### Ewentualne przyszłe ulepszenia
- [ ] Walidacje ActiveRecord - część komunikatów walidacji może być po angielsku
- [ ] Dodatkowe widoki admin (show, edit, new dla poszczególnych zasobów)
- [ ] Ewentualne nowe widoki dodane w przyszłości

---

## Notatki

### Struktura kluczy w `config/locales/pl.yml`

```yaml
pl:
  enter:           # Strona wyboru roli
  navigation:      # Nawigacja (wszystkie layouty)
  dashboard:       # Dashboard nauczyciela
  management:      # Panel zarządzania szkołą
  admin:           # Panel globalnego admina
  student:         # Panel ucznia
  actions:         # Wspólne akcje (logout, save, cancel)
  common:          # Wspólne teksty
```

### Rozwiązane problemy

1. **JavaScript w widokach** - wiele widoków zawiera inline JavaScript z zahardkodowanymi tekstami - przetłumaczone bezpośrednio w kodzie JS
2. **Formularze dynamiczne** - modale i formularze generowane przez JS - przetłumaczone inline
3. **aria-labels** - wszystkie etykiety dostępności przetłumaczone na polski

---

## Historia zmian

| Data | Opis |
|------|------|
| 2025-01-13 | Utworzenie dokumentu, naprawione: enter, dashboard/index, layouts |
| 2025-12-13 | Przetłumaczone: dashboard (wszystkie widoki) |
| 2025-12-13 | Przetłumaczone: management (wszystkie widoki włącznie z parents) |
| 2025-12-13 | Przetłumaczone: admin/resources (wszystkie widoki) |
| 2025-12-13 | Przetłumaczone: student_dashboard (wszystkie widoki) |
| 2025-12-13 | Przetłumaczone: devise (sesje, hasła, linki) |
| 2025-12-13 | Naprawiono test student_dashboard_spec |
| 2025-12-13 | **Zakończono internacjonalizację wszystkich głównych widoków** |
