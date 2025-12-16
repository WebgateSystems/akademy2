# AKAdemy 2.0

[![CI](https://github.com/WebgateSystems/akademy2/actions/workflows/ci.yml/badge.svg)](https://github.com/WebgateSystems/akademy2/actions/workflows/ci.yml)
![Coverage](https://img.shields.io/badge/coverage-92.4%25-brightgreen)
[![Ruby](https://img.shields.io/badge/Ruby-3.4.6-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.1-D30001?logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

---

Languages: [Polski (default)](README.md) · English · [Українська](README.ua.md)

Educational platform for schools (Web panels + API for a mobile app).

More documentation (including **user flows**, roles/screens and API/Swagger) is available in `docs/README.md`.

## Local requirements

- **Ruby**: `3.4.6` (see `.ruby-version`)
- **PostgreSQL**: 13+ (15+ recommended)
- **Node.js** + **Yarn** (repo uses `yarn@3.2.0`, see `package.json`)
- **Elasticsearch 8.x** (optional; recommended for “School videos” search)
- **FFmpeg** (optional; auto `duration_sec` + thumbnails for uploaded videos)
- **Redis + Sidekiq** (optional in dev; needed if you run jobs via Sidekiq like in prod)

## System dependencies

- PostgreSQL 15+
- Node.js (assets: `esbuild`/`sass`)
- Elasticsearch 8.x (optional)

## Configuration

Defaults live in `config/settings.yml` (many values have ENV fallbacks).

Common environment variables:

- **`DATABASE_URL`** (or standard PG vars)
- **`DEVISE_JWT_SECRET_KEY`** (JWT secret; dev has a fallback in `config/settings.yml`)
- **`ELASTICSEARCH_URL`** (if you use ES; default `http://localhost:9200`)
- **`TWILIO_*` / `SMTP_*` / `YOUTUBE_*`** (optional integrations)

## Database

```bash
bin/rails db:prepare
```

Optional sample data (dev):

```bash
bin/rails db:seed
```

## Start (development)

1) Install Ruby deps:

```bash
bundle install
```

2) Install JS deps:

```bash
corepack enable
yarn install
```

3) Prepare DB and run dev (Rails + JS/CSS watchers):

```bash
bin/setup
```

Alternatively:

```bash
bin/rails db:prepare
bin/dev
```

## Tests

### Unit tests (RSpec)

```bash
bundle exec rspec
```

### E2E tests (Puppeteer)

End-to-end tests simulate real user interactions in a browser.

**Requirements:**
- Node.js + Yarn (Puppeteer installed automatically)
- Running application on `localhost:3000`
- Test data in database (`rake db:seed`)

**Run all tests:**

```bash
# Headless mode (fast, no visible browser)
rake test

# GUI mode (visible browser with cursor)
rake test:gui
```

**Run a single test:**

```bash
# Headless
rake test[superadmin-menu]

# With visible browser
rake test[superadmin-menu,gui]
```

**Available tests:**

| Test | Description |
|------|-------------|
| `superadmin-menu` | Superadmin panel menu navigation |
| `superadmin-users` | User management (filtering, editing) |
| `superadmin-content` | Content management (subjects, modules) |
| `principal-dashboard` | Principal panel menu |
| `principal-management` | Class, teacher, student management |
| `teacher-dashboard` | Teacher panel menu |
| `teacher-dashboard-full` | Full teacher functionality test |
| `student-dashboard` | Student panel menu |
| `student-dashboard-full` | Full student functionality test |
| `theme-switcher` | Light/dark theme switching |
| `dashboard-switcher` | Teacher↔principal dashboard switching |
| `subjects-dragdrop` | Subject drag & drop |

Details in `e2e/README.md`.

## OpenAPI / Swagger

UI is available at `/api-docs/index.html` and serves `docs/swagger/v1/swagger.yaml`.

Regenerate docs:

```bash
bundle exec rake rswag:specs:swaggerize
```

## FFmpeg (video processing)

FFmpeg is used for automatic video processing (duration extraction, thumbnail generation).

### Installation

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

### How it works

When a student uploads a video:
1. `ProcessVideoJob` is automatically enqueued
2. FFmpeg extracts video duration (stored in `duration_sec`)
3. FFmpeg captures a frame (at 1 second or the middle for short videos) as a thumbnail
4. Thumbnail is stored via a CarrierWave uploader

If FFmpeg is not installed, videos will still upload but without automatic duration/thumbnail.

## Elasticsearch

The app uses Elasticsearch for full-text search (the “School videos” feature).
The ES instance is **shared** between multiple projects — indices are prefixed with `akademy2_{environment}`.

### Configuration

In `config/settings.yml`:
```yaml
elasticsearch:
  url: http://localhost:9200
  index_prefix: akademy2
```

Or via environment variable:
```bash
export ELASTICSEARCH_URL=http://localhost:9200
```

### Index naming convention

```
{prefix}_{environment}_{model}
```

Examples:
- `akademy2_development_student_videos`
- `akademy2_staging_student_videos`
- `akademy2_production_student_videos`

### Managing indices

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

### Search examples

```ruby
# Basic search
StudentVideo.search("keyword")

# Search with filters
StudentVideo.search("keyword", where: { status: "approved", subject_id: "uuid" })

# Search with pagination
StudentVideo.search("keyword", page: 1, per_page: 20)
```

## Services / components

- **Sidekiq** – background job processing (production; in development jobs may run inline by default)
- **Elasticsearch** – full-text search for “School videos”
- **SMTP** – email delivery (Devise notifications)

## Deployment

Deployment is done via Capistrano:

```bash
cap staging deploy
cap production deploy
```


