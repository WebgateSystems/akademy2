# AKAdemy 2.0

[![CI](https://github.com/WebgateSystems/akademy2/actions/workflows/ci.yml/badge.svg)](https://github.com/WebgateSystems/akademy2/actions/workflows/ci.yml)
![Coverage](https://img.shields.io/badge/coverage-91.2%25-brightgreen)
[![Ruby](https://img.shields.io/badge/Ruby-3.4.6-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.1-D30001?logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

---

Języki: Polski (domyślny) · [English](README.en.md) · [Українська](README.ua.md)

Platforma edukacyjna dla szkół (panel WWW + API dla aplikacji mobilnej).

Więcej dokumentacji (w tym **flow użytkowników**, rola/ekrany oraz API/Swagger) znajdziesz w `docs/README.md`.

## Wymagania (lokalnie)

- **Ruby**: `3.4.6` (patrz `.ruby-version`)
- **PostgreSQL**: 13+ (zalecane 15+)
- **Node.js** + **Yarn** (repo używa `yarn@3.2.0`, patrz `package.json`)
- **Elasticsearch 8.x** (opcjonalne, ale zalecane dla wyszukiwania „School videos”)
- **FFmpeg** (opcjonalne; automatyczne `duration_sec` + miniatury do wideo)
- **Redis + Sidekiq** (opcjonalne w dev; wymagane jeśli uruchamiasz joby przez Sidekiq jak na prod)

## Zależności systemowe

- PostgreSQL 15+
- Node.js (dla assetów: `esbuild`/`sass`)
- Elasticsearch 8.x (opcjonalnie)

## Konfiguracja

Domyślne ustawienia są w `config/settings.yml` (część wartości ma fallbacki do ENV).

Najczęściej używane zmienne środowiskowe:

- **`DATABASE_URL`** lub standardowe zmienne PG (host/user/password)
- **`DEVISE_JWT_SECRET_KEY`** (sekret do JWT; w dev ma domyślną wartość w `config/settings.yml`)
- **`ELASTICSEARCH_URL`** (jeśli używasz ES; domyślnie `http://localhost:9200`)
- **`TWILIO_*` / `SMTP_*` / `YOUTUBE_*`** (opcjonalnie – integracje)

## Baza danych

```bash
bin/rails db:prepare
```

Jeśli chcesz wgrać dane przykładowe (dev):

```bash
bin/rails db:seed
```

## Testy

### Testy jednostkowe (RSpec)

```bash
bundle exec rspec
```

### Testy E2E (Puppeteer)

Testy end-to-end symulują rzeczywiste interakcje użytkownika w przeglądarce.

**Wymagania:**
- Node.js + Yarn (Puppeteer zainstalowany automatycznie)
- Uruchomiona aplikacja na `localhost:3000`
- Dane testowe w bazie (`rake db:seed`)

**Uruchomienie wszystkich testów:**

```bash
# Tryb headless (szybki, bez widocznej przeglądarki)
rake test

# Tryb GUI (z widoczną przeglądarką i kursorem)
rake test:gui
```

**Uruchomienie pojedynczego testu:**

```bash
# Headless
rake test[superadmin-menu]

# Z widoczną przeglądarką
rake test[superadmin-menu,gui]
```

**Dostępne testy:**

| Test | Opis |
|------|------|
| `superadmin-menu` | Nawigacja menu panelu superadmina |
| `superadmin-users` | Zarządzanie użytkownikami (filtrowanie, edycja) |
| `superadmin-content` | Zarządzanie treściami (przedmioty, moduły) |
| `principal-dashboard` | Menu panelu dyrektora |
| `principal-management` | Zarządzanie klasami, nauczycielami, uczniami |
| `teacher-dashboard` | Menu panelu nauczyciela |
| `teacher-dashboard-full` | Pełny test funkcji nauczyciela |
| `student-dashboard` | Menu panelu ucznia |
| `student-dashboard-full` | Pełny test funkcji ucznia |
| `theme-switcher` | Przełączanie tematu jasny/ciemny |
| `dashboard-switcher` | Przełączanie nauczyciel↔dyrektor |
| `subjects-dragdrop` | Drag & drop przedmiotów |

Szczegóły w `e2e/README.md`.

## Start aplikacji (development)

1) Zainstaluj zależności Ruby:

```bash
bundle install
```

2) Zainstaluj zależności JS:

```bash
corepack enable
yarn install
```

3) Przygotuj bazę i uruchom dev (Rails + watchery JS/CSS):

```bash
bin/setup
```

Alternatywnie (bez `bin/setup`):

```bash
bin/rails db:prepare
bin/dev
```

## Dokumentacja OpenAPI (Swagger)

UI jest dostępne pod `/api-docs/index.html` i serwuje plik `docs/swagger/v1/swagger.yaml`.

Regenerowanie dokumentacji:
```bash
bundle exec rake rswag:specs:swaggerize
```

## FFmpeg (przetwarzanie wideo)

FFmpeg jest potrzebny do automatycznego przetwarzania wideo (wykrywanie czasu trwania, generowanie miniatur).

### Instalacja

**macOS:**
```bash
brew install ffmpeg
```

**Ubuntu/Debian:**
```bash
sudo apt-get install ffmpeg mediainfo
```

**CentOS/RHEL:**
```bash
sudo yum install ffmpeg
```

### Jak to działa

Gdy uczeń wgrywa wideo:
1. `ProcessVideoJob` is automatically enqueued
2. FFmpeg wyciąga `duration_sec`
3. FFmpeg generuje miniaturę (klatka z 1 sekundy lub ze środka dla krótkich filmów)
4. Miniatura jest zapisywana przez uploader CarrierWave

Jeśli FFmpeg nie jest zainstalowany, upload nadal zadziała, ale bez automatycznego czasu trwania/miniatur.

## Elasticsearch

Aplikacja używa Elasticsearch do wyszukiwania pełnotekstowego (funkcja „School videos”).
Instancja ES jest **współdzielona** między projektami – indeksy mają prefiks `akademy2_{environment}`.

### Konfiguracja

W `config/settings.yml`:
```yaml
elasticsearch:
  url: http://localhost:9200
  index_prefix: akademy2
```

Albo przez zmienną środowiskową:
```bash
export ELASTICSEARCH_URL=http://localhost:9200
```

### Konwencja nazw indeksów

```
{prefix}_{environment}_{model}
```

Przykłady:
- `akademy2_development_student_videos`
- `akademy2_staging_student_videos`
- `akademy2_production_student_videos`

### Zarządzanie indeksami

```bash
# Start Rails console
rails c

# Reindex all StudentVideo records
StudentVideo.reindex

# Check index name
StudentVideo.searchkick_index.name
# => "akademy2_production_student_videos"

# Check if index exists
StudentVideo.searchkick_index.exists?

# Delete and recreate index
StudentVideo.reindex(force: true)

# Reindex asynchronously (via Sidekiq)
StudentVideo.reindex(async: true)
```

### Przykłady wyszukiwania

```ruby
# Basic search
StudentVideo.search("keyword")

# Search with filters
StudentVideo.search("keyword", where: { status: "approved", subject_id: "uuid" })

# Search with pagination
StudentVideo.search("keyword", page: 1, per_page: 20)
```

## Usługi / komponenty

- **Sidekiq** – przetwarzanie zadań w tle (w produkcji; w development domyślnie joby mogą działać inline)
- **Elasticsearch** – wyszukiwanie pełnotekstowe dla „School videos”
- **SMTP** – wysyłka e-maili (powiadomienia Devise)

## Deployment

Wdrożenia są realizowane przez Capistrano:
```bash
cap staging deploy
cap production deploy
```
