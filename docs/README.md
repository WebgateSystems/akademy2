# Dokumentacja (AKAdemy 2.0)

Ta dokumentacja jest zebrana tak, żeby dało się szybko:

- zrozumieć **role i standardowe ścieżki użytkowników** (admin → szkoła → nauczyciel → uczeń),
- znaleźć **kontrakt API** (Swagger/OpenAPI),
- odnieść się do **założeń projektu** (opisanych w Markdown w tym repo).

## Spis treści

- **Założenia projektu (Markdown)**
  - [`docs/zalozenia_projektu.md`](zalozenia_projektu.md)

- **Flow użytkowników (standardowe ścieżki)**
  - [`docs/flow_uzytkownikow.md`](flow_uzytkownikow.md)

- **API**
  - Swagger: [`docs/swagger/v1/swagger.yaml`](swagger/v1/swagger.yaml)
  - Jak korzystać z API + autoryzacja: [`docs/api.md`](api.md)

- **Architektura treści edukacyjnych**
  - [`docs/architecture_learning_modules.md`](architecture_learning_modules.md)
  - [`docs/learning_modules_diagram.md`](learning_modules_diagram.md)
  - Diagram relacji encji (PNG): [`docs/relations.png`](relations.png)

## Gdzie jest „instrukcja uruchomienia”?

Root `README.md` jest celowo skupiony na podnoszeniu projektu i testach:

- [`README.md`](../README.md) (PL)
- [`README.en.md`](../README.en.md) (EN)

## Sidekiq / ActiveJob — typowy problem po zmianie typu joba

Jeśli job był kiedyś **ActiveJob** (np. `class XJob < ApplicationJob`) i był enqueuowany przez `perform_later`,
a potem został zmieniony na **Sidekiq worker** (np. `include Sidekiq::Job` / `class XJob < BaseSidekiqJob`)
to w Redisie mogą zostać stare wpisy ActiveJob. Wtedy Sidekiq przy próbie wykonania może wyrzucać błąd typu:

- `undefined method 'deserialize' for an instance of XJob`

Co zrobić po deployu:

- **Zrestartuj Sidekiq** po każdym deployu (żeby nie trzymał starego kodu w pamięci).
- **Usuń / opróżnij stare joby** z kolejki (bo to już payloady niekompatybilne z nową klasą).

Przykłady (wybierz adekwatne do sytuacji):

- Jeśli problem siedzi w `retry`/`dead` (najczęściej):
  - `bundle exec sidekiqctl quiet tmp/pids/sidekiq.pid`
  - `bundle exec sidekiqctl stop tmp/pids/sidekiq.pid 10`
  - wyczyść `Retry`/`Dead` z UI Sidekiq albo skryptem (patrz niżej)
  - uruchom Sidekiq ponownie (np. przez systemd / kamal / docker compose)

- Jeśli chcesz to zrobić skryptowo, dodaj tymczasową komendę w konsoli Rails na serwerze:
  - `bundle exec rails c -e production`
  - i usuń błędne joby z `Sidekiq::RetrySet`/`Sidekiq::DeadSet` po `wrapped`/`class` (ostrożnie!).

Uwaga: `ActiveJob::DeserializationError` w `SendEmailJob` to osobny przypadek — zwykle oznacza, że job
odnosi się do rekordu (GlobalID), którego już nie ma w bazie (np. usunięty użytkownik/zasób).


