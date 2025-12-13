# Postęp internacjonalizacji (I18n)

Ten dokument śledzi postęp prac nad internacjonalizacją aplikacji AKAdemy.

**Domyślny locale:** `pl` (polski)  
**Dostępne locales:** `pl`, `en`

---

## ✅ Zrobione

### Konfiguracja
- [x] `config/application.rb` - ustawiony `default_locale: :pl`
- [x] `config/locales/pl.yml` - dodane tłumaczenia dla nawigacji, dashboard, enter

### Layouts
- [x] `app/views/layouts/enter.html.slim` - tytuł strony
- [x] `app/views/layouts/management.html.erb` - nawigacja boczna (School profile, Administration, Teachers, Students, Parents, Classes, Years)
- [x] `app/views/layouts/admin.html.slim` - nawigacja boczna (Schools, Headmasters, Teachers, Students, Activity log, Subjects, Units, Modules, Content)

### Widoki - Enter (strona główna wyboru roli)
- [x] `app/views/enter/index.html.slim` - "Kim jesteś?", Uczeń, Nauczyciel, Administracja

### Widoki - Dashboard (nauczyciel)
- [x] `app/views/dashboard/index.html.slim` - hero section, statystyki, wyniki uczniów
- [x] `app/views/dashboard/quiz_results.html.slim` - nagłówki tabeli
- [x] `app/views/dashboard/_sidebar.html.slim` - nawigacja boczna, aria-labels
- [x] `app/views/dashboard/_top_bar.html.slim` - górny pasek, aria-labels

### Widoki - Management
- [x] `app/views/management/_top_bar.html.erb` - tytuł, aria-labels

### Widoki - Devise (logowanie)
- [x] `app/views/devise/shared/_links.slim` - linki (zaloguj, zarejestruj, nie pamiętasz hasła)
- [x] `config/locales/devise.pl.yml` - dodane shared.links

### Widoki - Rejestracja
- [x] `app/views/register/wizard/student.slim` - formularz rejestracji ucznia
- [x] `app/views/register/wizard/teacher.slim` - formularz rejestracji nauczyciela
- [x] `app/views/register/wizard/profile.slim` - formularz uzupełniania profilu

### Widoki - Shared
- [x] `app/views/shared/_theme_toggle.html.slim` - aria-label
- [x] `app/views/devise/shared/_error_messages.html.erb` - używa I18n

### Widoki - Admin
- [x] `app/views/admin/_top_bar.html.slim` - aria-labels
- [x] `app/views/admin/sessions/new.html.erb` - logowanie administratora

### Mailery Devise (wszystkie po polsku)
- [x] `app/views/devise/mailer/reset_password_instructions.html.mjml`
- [x] `app/views/devise/mailer/confirmation_instructions.html.mjml`
- [x] `app/views/devise/mailer/email_changed.html.mjml`
- [x] `app/views/devise/mailer/password_change.html.mjml`
- [x] `app/views/devise/mailer/unlock_instructions.html.mjml`

### Widoki - Devise Passwords (już po polsku)
- [x] `app/views/devise/passwords/new.slim` - resetowanie hasła
- [x] `app/views/devise/passwords/edit.slim` - ustawianie nowego hasła/PIN

### Landing Page (już po polsku)
- [x] `app/views/layouts/landing.html.slim`

---

## 🔄 W trakcie

*(brak)*

---

## ❌ Do zrobienia

### Widoki - Dashboard (nauczyciel)
- [ ] `app/views/dashboard/students.html.slim` - lista uczniów, statusy
- [ ] `app/views/dashboard/show_student.html.slim` - szczegóły ucznia
- [ ] `app/views/dashboard/notifications.html.slim` - powiadomienia
- [ ] `app/views/dashboard/student_videos.html.slim` - filmy uczniów
- [ ] `app/views/dashboard/pending_school_enrollment.html.slim` - oczekiwanie na zatwierdzenie
- [ ] `app/views/dashboard/no_school.html.slim` - brak szkoły

### Widoki - Management (dyrekcja)
- [ ] `app/views/management/teachers/index.html.erb` - lista nauczycieli, formularze, JavaScript
- [ ] `app/views/management/students/index.html.erb` - lista uczniów
- [ ] `app/views/management/administrations/index.html.slim` - lista administracji
- [ ] `app/views/management/notifications/index.html.erb` - filtrowanie powiadomień
- [ ] `app/views/management/classes/index.html.erb` - lista klas
- [ ] `app/views/management/parents/index.html.erb` - lista rodziców
- [ ] `app/views/management/years/index.html.erb` - lata akademickie
- [ ] `app/views/management/school_profile/show.html.erb` - profil szkoły

### Widoki - Admin (globalny admin)
- [ ] `app/views/admin/_top_bar.html.slim` - górny pasek
- [ ] `app/views/admin/schools/` - wszystkie widoki szkół
- [ ] `app/views/admin/users/` - zarządzanie użytkownikami
- [ ] `app/views/admin/subjects/` - przedmioty
- [ ] `app/views/admin/units/` - jednostki
- [ ] `app/views/admin/learning_modules/` - moduły
- [ ] `app/views/admin/contents/` - treści

### Widoki - Student (uczeń)
- [ ] `app/views/student_dashboard/` - wszystkie widoki ucznia
- [ ] `app/views/home/` - strona główna ucznia

### Widoki - Rejestracja/Logowanie
- [ ] `app/views/devise/` - formularze Devise
- [ ] `app/views/registrations/` - rejestracja
- [ ] `app/views/sessions/` - logowanie

### Widoki - Wspólne
- [ ] `app/views/shared/` - komponenty współdzielone

### Mailers
- [ ] `app/views/devise_mailer/` - emaile Devise
- [ ] `app/views/user_mailer/` - emaile użytkownika

### Testy
- [ ] Przejrzeć testy pod kątem zahardkodowanych tekstów
- [ ] Zmienić asercje na sprawdzanie kluczy I18n lub obecności elementów

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

### Problematyczne miejsca

1. **JavaScript w widokach** - wiele widoków (np. `teachers/index.html.erb`) zawiera inline JavaScript z zahardkodowanymi tekstami. Wymagają:
   - Przeniesienia tekstów do atrybutów `data-*` 
   - Lub użycia `I18n-js` gem

2. **Formularze dynamiczne** - modale i formularze generowane przez JS

3. **Walidacje ActiveRecord** - część komunikatów walidacji jest po angielsku

---

## Historia zmian

| Data | Opis |
|------|------|
| 2025-01-13 | Utworzenie dokumentu, naprawione: enter, dashboard/index, layouts |

