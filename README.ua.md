# AKAdemy 2.0

[![CI](https://github.com/WebgateSystems/akademy2/actions/workflows/ci.yml/badge.svg)](https://github.com/WebgateSystems/akademy2/actions/workflows/ci.yml)
![Coverage](https://img.shields.io/badge/coverage-92.8%25-brightgreen)
[![Ruby](https://img.shields.io/badge/Ruby-3.4.6-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.1-D30001?logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

---

Мови: [Polski (за замовчуванням)](README.md) · [English](README.en.md) · Українська

Освітня платформа для шкіл (веб-панель + API для мобільного застосунку).

Додаткову документацію (включаючи **flow користувачів**, ролі/екрани та API/Swagger) можна знайти в `docs/README.md`.

## Вимоги (локально)

- **Ruby**: `3.4.6` (див. `.ruby-version`)
- **PostgreSQL**: 13+ (рекомендовано 15+)
- **Node.js** + **Yarn** (репозиторій використовує `yarn@3.2.0`, див. `package.json`)
- **Elasticsearch 8.x** (опціонально, але рекомендовано для пошуку "School videos")
- **FFmpeg** (опціонально; автоматичне визначення `duration_sec` + мініатюри для відео)
- **Redis + Sidekiq** (опціонально в dev; обов'язково якщо запускаєте jobs через Sidekiq як на prod)

## Системні залежності

- PostgreSQL 15+
- Node.js (для assets: `esbuild`/`sass`)
- Elasticsearch 8.x (опціонально)

## Конфігурація

Стандартні налаштування знаходяться в `config/settings.yml` (частина значень має fallback до ENV).

Найчастіше використовувані змінні середовища:

- **`DATABASE_URL`** або стандартні змінні PG (host/user/password)
- **`DEVISE_JWT_SECRET_KEY`** (секрет для JWT; в dev має значення за замовчуванням в `config/settings.yml`)
- **`ELASTICSEARCH_URL`** (якщо використовуєте ES; за замовчуванням `http://localhost:9200`)
- **`TWILIO_*` / `SMTP_*` / `YOUTUBE_*`** (опціонально – інтеграції)

## База даних

```bash
bin/rails db:prepare
```

Якщо хочете завантажити тестові дані (dev):

```bash
bin/rails db:seed
```

## Тести

### Юніт-тести (RSpec)

```bash
bundle exec rspec
```

### E2E тести (Puppeteer)

End-to-end тести симулюють реальні взаємодії користувача в браузері.

**Вимоги:**
- Node.js + Yarn (Puppeteer встановлюється автоматично)
- Запущений застосунок на `localhost:3000`
- Тестові дані в базі (`rake db:seed`)

**Запуск усіх тестів:**

```bash
# Headless режим (швидкий, без видимого браузера)
rake test

# GUI режим (з видимим браузером і курсором)
rake test:gui
```

**Запуск окремого тесту:**

```bash
# Headless
rake test[superadmin-menu]

# З видимим браузером
rake test[superadmin-menu,gui]
```

**Доступні тести:**

| Тест | Опис |
|------|------|
| `superadmin-menu` | Навігація меню панелі суперадміна |
| `superadmin-users` | Керування користувачами (фільтрування, редагування) |
| `superadmin-content` | Керування контентом (предмети, модулі) |
| `principal-dashboard` | Меню панелі директора |
| `principal-management` | Керування класами, вчителями, учнями |
| `teacher-dashboard` | Меню панелі вчителя |
| `teacher-dashboard-full` | Повний тест функцій вчителя |
| `student-dashboard` | Меню панелі учня |
| `student-dashboard-full` | Повний тест функцій учня |
| `theme-switcher` | Перемикання теми світла/темна |
| `dashboard-switcher` | Перемикання вчитель↔директор |
| `subjects-dragdrop` | Drag & drop предметів |

Деталі в `e2e/README.ua.md`.

## Запуск застосунку (development)

1) Встановіть залежності Ruby:

```bash
bundle install
```

2) Встановіть залежності JS:

```bash
corepack enable
yarn install
```

3) Підготуйте базу і запустіть dev (Rails + watchers JS/CSS):

```bash
bin/setup
```

Альтернативно (без `bin/setup`):

```bash
bin/rails db:prepare
bin/dev
```

## Документація OpenAPI (Swagger)

UI доступний за адресою `/api-docs/index.html` і обслуговує файл `docs/swagger/v1/swagger.yaml`.

Регенерація документації:
```bash
bundle exec rake rswag:specs:swaggerize
```

## FFmpeg (обробка відео)

FFmpeg потрібен для автоматичної обробки відео (визначення тривалості, генерація мініатюр).

### Встановлення

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

### Як це працює

Коли учень завантажує відео:
1. `ProcessVideoJob` автоматично ставиться в чергу
2. FFmpeg витягує `duration_sec`
3. FFmpeg генерує мініатюру (кадр з 1 секунди або з середини для коротких відео)
4. Мініатюра зберігається через uploader CarrierWave

Якщо FFmpeg не встановлено, завантаження все одно працюватиме, але без автоматичної тривалості/мініатюр.

## Elasticsearch

Застосунок використовує Elasticsearch для повнотекстового пошуку (функція "School videos").
Інстанс ES є **спільним** між проектами – індекси мають префікс `akademy2_{environment}`.

### Конфігурація

В `config/settings.yml`:
```yaml
elasticsearch:
  url: http://localhost:9200
  index_prefix: akademy2
```

Або через змінну середовища:
```bash
export ELASTICSEARCH_URL=http://localhost:9200
```

### Конвенція назв індексів

```
{prefix}_{environment}_{model}
```

Приклади:
- `akademy2_development_student_videos`
- `akademy2_staging_student_videos`
- `akademy2_production_student_videos`

### Керування індексами

```bash
# Запуск Rails console
rails c

# Переіндексація всіх записів StudentVideo
StudentVideo.reindex

# Перевірка назви індексу
StudentVideo.searchkick_index.name
# => "akademy2_production_student_videos"

# Перевірка чи існує індекс
StudentVideo.searchkick_index.exists?

# Видалення і перестворення індексу
StudentVideo.reindex(force: true)

# Асинхронна переіндексація (через Sidekiq)
StudentVideo.reindex(async: true)
```

### Приклади пошуку

```ruby
# Базовий пошук
StudentVideo.search("keyword")

# Пошук з фільтрами
StudentVideo.search("keyword", where: { status: "approved", subject_id: "uuid" })

# Пошук з пагінацією
StudentVideo.search("keyword", page: 1, per_page: 20)
```

## Сервіси / компоненти

- **Sidekiq** – обробка фонових завдань (на production; в development за замовчуванням jobs можуть працювати inline)
- **Elasticsearch** – повнотекстовий пошук для "School videos"
- **SMTP** – відправка e-mail (повідомлення Devise)

## Deployment

Деплой реалізований через Capistrano:
```bash
cap staging deploy
cap production deploy
```

