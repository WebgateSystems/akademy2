# Analiza: „upstream sent too big header” – sesja i nagłówki

## Skąd błąd

Nginx zgłasza, że **nagłówki odpowiedzi z Pumy są za duże** (m.in. `Set-Cookie`). Jedna wspólna przyczyna w Rails to **zbyt duża sesja w CookieStore**: cała sesja jest w jednym ciasteczku `_akademy_session`. Gdy sesja urośnie (kilka KB), serializacja + Base64 potrafi dać kilka–kilkanaście KB w nagłówku; przy domyślnych buforach Nginx (np. 4–8 KB) otrzymujesz 502.

Poniżej: co ląduje w sesji, gdzie jest ryzyko, oraz **możliwe scenariusze** (od szybkich po docelowe).

---

## 1. Co jest trzymane w sesji (CookieStore)

Źródło: `config/application.rb` → `ActionDispatch::Session::CookieStore, key: '_akademy_session'`.  
**Jedno ciasteczko** = cała sesja (Rails + Devise/Warden).

### 1.1. Klucze sesji (grep po `session[`)

| Klucz | Użycie | Rozmiar (szac.) |
|-------|--------|------------------|
| **`register_wizard`** | Webowy kreator rejestracji (profil, telefon, PIN, szkoła/klasa) | **największy – patrz niżej** |
| `join_class_token` | Token dołączenia do klasy (string) | mały |
| `join_school_token` | Token dołączenia do szkoły (string) | mały |
| `join_school_id` | ID szkoły (UUID) | mały |
| `return_to` | Zapamiętany URL przekierowania po logowaniu | mały/średni (długie URL?) |
| `user_return_to` | Jak wyżej (dashboard, management) | mały/średni |
| `last_redirect_path` | Ochrona przed pętlą przekierowań | mały |
| `last_redirect_count` | Licznik przekierowań | mały |
| `last_redirect_time` | Timestamp | mały |
| `admin_id` | JWT dla panelu admina (logowanie admin) | ~200–400 B (tylko `user_id` + `exp`) |

### 1.2. Zawartość `register_wizard` (główny kandydat na „za duży” cookie)

Tworzone w `Register::WizardFlow`, używane w `/register/*` (w tym **POST /register/verify-phone**).

- **`profile`** – z formularzy:
  - Student: `first_name`, `last_name`, `birthdate`, `email`, `phone` (ProfileForm).
  - Nauczyciel: to samo + **`password`**, **`password_confirmation`** (TeacherProfileForm) – **hasło w sesji to też ryzyko bezpieczeństwa**.
- **`phone`** – `sms_code`, `verified`, `phone`.
- **`school`** – `join_token`, `school_id`.
- **`school_class`** – `join_token`, `school_class_id`, `school_id`.
- **`pin_temp`** / **`pin`** – PIN (student).
- **`user`** – `user_id` (po utworzeniu użytkownika).
- **`registration_type`** – `'student'` / `'teacher'`.

Łącznie: przy teacher flow w sesji są m.in. **plaintextowe hasła**, kilka UUID i stringów. Po serializacji (Marshal/JSON + Base64 w CookieStore) + reszta sesji (Devise, return_to, itd.) **nagłówek Set-Cookie może przekroczyć limity Nginx**.

### 1.3. Devise / Warden

- Dla logowania **przeglądarki** Devise używa **tej samej sesji** (CookieStore).
- W sesji Warden trzyma zwykle **tylko identyfikator użytkownika** (np. `User`, id), nie cały obiekt – to raczej małe.

### 1.4. JWT (API vs admin)

- **API** (`/api/v1/auth/login`): JWT w **nagłówku odpowiedzi** (np. `Authorization`), **nie w cookie** – nie przyczynia się do rozmiaru sesji.
- **Admin**: JWT jest w **sesji** (`session[:admin_id]`). Payload to `user_id` + `exp` – rozmiar JWT jest mały.

---

## 2. Co NIE jest w sesji (OK)

- **Rejestracja z API** używa modelu **`RegistrationFlow`** (DB, `encrypts :data`) i **flow_id** – dane kreatora **nie** leżą w cookie.
- **Listy uprawnień/rol** – nie są trzymane w sesji jako tablice w cookie (role są w DB, odczytywane przy `current_user`).
- **Params** – nie ma zapisu całego `params` do sesji.

---

## 3. Możliwe scenariusze (od „łatka” do docelowego)

### Scenariusz A: Zmniejszyć zawartość `register_wizard` (bez zmiany storage)

- **Teacher:** **Nie zapisywać `password` i `password_confirmation` w sesji.**  
  Wymaga zmiany flow: np. hasło przekazywane tylko w jednym żądaniu (np. szyfrowane w formularzu i odszyfrowane tylko przy `CreateTeacherAfterVerify`) albo **jedno żądanie „profile + verify + create teacher”** (np. po weryfikacji SMS wysyłamy hasło w kolejnym, już „zatwierdzonym” requestcie) – wtedy hasło nie musi leżeć w sesji.  
  To zmniejsza rozmiar i poprawia bezpieczeństwo (brak hasła w cookie).
- **Wizard:** Trzymać w `register_wizard` tylko **minimalne pola** potrzebne do kolejnych kroków (np. nie trzymać zbędnych pól z formularzy).
- **Po zakończeniu rejestracji:** Wywołać `flow.finish!` (już jest) i ewentualnie **jawną** `session.delete(:register_wizard)` tuż po `sign_in`, na wypadek gdyby coś zostało.

**Plusy:** Brak nowej zależności, mniejszy cookie.  
**Minusy:** Teacher flow wymaga przemyślenia przekazania hasła (bez przechowywania w sesji).

---

### Scenariusz B: Redis tylko na dane kreatora rejestracji (web)

- Dane kreatora **web** (`register_wizard`) trzymać **w Redisie** pod kluczem np. `register_wizard:#{session_id}` lub `register_wizard:#{secure_random}`.
- W cookie/sesji tylko **id flow** (np. UUID, ~36 znaków) lub w ogóle tylko własny mały token odczytujący z Redis.
- Po zakończeniu rejestracji: usuwać wpis z Redis; TTL np. 1 h.

**Plusy:** Cookie małe, hasło nie w cookie.  
**Minusy:** Wymaga Redis; trzeba wyciągnąć odczyt/zapis `register_wizard` do jednego miejsca (np. wrapper wokół WizardFlow).

---

### Scenariusz C: Cała sesja w Redis session store (właśnie ten został wybrany)

- Zamiana **CookieStore na Redis session store** (np. `redis-session-store` lub `rack-session-redis`).
- W cookie tylko **session_id** (np. 32 B); cała sesja (w tym `register_wizard`, Devise, return_to, admin_id) w Redisie.

**Plusy:** Rozmiar nagłówka praktycznie stały; możesz trzymać większe sesje bez „too big header”.  
**Minusy:** Zależność od Redis; deployment/backup Redis; wygaśnięcie sesji zależy od TTL w Redis.

---

### Scenariusz D: Hybryda – sesja w Redis + minimalna zawartość

- Wdrożyć **Scenariusz C** (Redis session store).
- Dodatkowo wdrożyć **Scenariusz A** w zakresie: **nie trzymać haseł w sesji** (nawet w Redisie to lepsza praktyka) i czyścić `register_wizard` zaraz po zakończeniu rejestracji.

**Plusy:** Maksymalna kontrola rozmiaru i bezpieczeństwa.  
**Minusy:** Najwięcej zmian.

---

## 4. Rekomendacje

- **Docelowo:**  
  - **Redis session store (Scenariusz C)** – eliminuje problem „za duży nagłówek” i pozwala w przyszłości trzymać nieco więcej w sesji bez limitu 4 KB (cookie).  
  - **Nie trzymać haseł w sesji (Scenariusz A dla teacher)** – zmiana flow tak, by hasło nie trafiało do `register_wizard` (ani cookie, ani Redis).

- **Na szybko (bez Redis):**  
  - Zredukować zawartość `register_wizard` i **usunąć password/password_confirmation z zapisu do sesji** w teacher flow (wymaga zmiany sposobu przekazania hasła do `CreateTeacherAfterVerify`).  
  - Można wtedy zostawić tymczasową „łatkę” w Nginx (większe bufory), ale traktować ją jako zabezpieczenie, a nie rozwiązanie docelowe.

---

## 5. Pliki do ewentualnych zmian (quick reference)

- **Sesja / store:**  
  `config/application.rb` (CookieStore → ewentualnie Redis).
- **Zapis do sesji:**  
  `app/services/register/wizard_flow.rb`,  
  `app/controllers/register/wizard_controller.rb`,  
  `app/interactors/register/profile_submit.rb`,  
  `app/interactors/register/teacher_profile_submit.rb` (tu ląduje `to_h` z hasłami),  
  `app/interactors/register/send_sms_code.rb` (phone w flow).
- **Użycie flow (teacher + hasło):**  
  `app/interactors/register/create_teacher_after_verify.rb` (czyta `profile['password']` z flow).
- **Redirect loop / return_to:**  
  `app/controllers/application_controller.rb`,  
  `app/controllers/dashboard_controller.rb`,  
  `app/controllers/management/base_controller.rb`,  
  `app/controllers/student_dashboard_controller.rb` – same wartości to zwykle krótkie ścieżki; można ograniczyć długość zapisywanych URLi (np. tylko path bez query).
- **Admin JWT w sesji:**  
  `app/controllers/admin/sessions_controller.rb`, `app/controllers/admin/base_controller.rb` – sam JWT jest mały; przy Redis session store nadal można go trzymać w sesji.

---

## 6. Wdrożenie (Scenariusz C)

Wdrożono **Redis session store** i **czyszczenie danych kreatora po logowaniu**:

- **Gem:** `redis-actionpack` (~> 5.5).
- **Konfiguracja:** W `config/application.rb` – gdy jest ustawione `REDIS_URL`, sesja idzie do Redis ( osobna baza, np. `/1`, żeby nie mieszać z Sidekiq `/0`). Gdy brak `REDIS_URL` (np. dev bez Redis) – nadal `CookieStore`.
- **Czyszczenie po logowaniu:** W `ApplicationController#after_sign_in_path_for` wywoływane jest `clear_registration_wizard_data` (usuwa `register_wizard`, `join_class_token`, `join_school_token`, `join_school_id`). To samo wywołanie jest w `Admin::SessionsController#handle_success`, żeby przy logowaniu do panelu admina też usunąć ewentualne dane kreatora.

**Na serwerze:** upewnij się, że w production jest ustawione `REDIS_URL` (już jest przy Sidekiq). Po wdrożeniu uruchom `bundle install` i restart Pumy.
