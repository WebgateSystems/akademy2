# AKAdemy 2.0

Educational platform for Polish schools.

## Ruby version

3.4.6

## System dependencies

- PostgreSQL 15+
- Redis (for Sidekiq)
- Elasticsearch 8.x (shared instance, port 9200)
- Node.js (for assets)

## Configuration

Copy environment variables:
```bash
cp .env.example .env
```

Key environment variables:
```bash
ELASTICSEARCH_URL=http://localhost:9200
REDIS_URL=redis://localhost:6379/4
```

## Database setup

```bash
rails db:create
rails db:migrate
rails db:seed
```

## How to run the test suite

```bash
bundle exec rspec
```

## OpenAPI documentation

Accessible at `/api-docs/index.html`

Regenerate documentation:
```bash
bundle exec rake rswag:specs:swaggerize
```

## FFmpeg (Video Processing)

FFmpeg is required for automatic video processing (duration extraction, thumbnail generation).

### Installation

**macOS:**
```bash
brew install ffmpeg
```

**Ubuntu/Debian:**
```bash
sudo apt-get install ffmpeg
```

**CentOS/RHEL:**
```bash
sudo yum install ffmpeg
```

### How it works

When a student uploads a video:
1. `ProcessVideoJob` is automatically enqueued
2. FFmpeg extracts video duration (stored in `duration_sec`)
3. FFmpeg captures a frame at 1 second (or middle for short videos) as thumbnail
4. Thumbnail is stored via CarrierWave uploader

If FFmpeg is not installed, videos will still upload but without automatic duration/thumbnail.

## Elasticsearch

The app uses Elasticsearch for full-text search (School Videos feature).
ES instance is **shared** between multiple projects - indices are prefixed with `akademy2_{environment}`.

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

## Services

- **Sidekiq** - Background job processing
- **Elasticsearch** - Full-text search for School Videos
- **SMTP** - Email delivery (Devise notifications)

## Deployment

Using Capistrano:
```bash
cap staging deploy
cap production deploy
```
