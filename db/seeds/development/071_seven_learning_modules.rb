# frozen_string_literal: true

# Seeds dla 7 modułów edukacyjnych z mediami z CDN
# Pobiera pliki z cdn.akademy.edu.pl i uploaduje je lokalnie
#
# UWAGA: Ten seed wymaga dostępu do sieci (cdn.akademy.edu.pl)

require 'open-uri'
require 'yaml'
require 'tempfile'
require 'fileutils'

# === Wczytanie konfiguracji CDN ===
CDN_CONFIG_PATH = Rails.root.join('config/cdn_content.yml')
unless File.exist?(CDN_CONFIG_PATH)
  log('⚠️  Brak pliku config/cdn_content.yml - pomijam seedy CDN') if defined?(log)
  return
end

CDN_CONFIG = YAML.load_file(CDN_CONFIG_PATH, symbolize_names: false)
CDN_BASE_URL = CDN_CONFIG['cdn_base_url']
UUIDS = CDN_CONFIG['uuids']
SUBJECTS_CONFIG = CDN_CONFIG['subjects']

log('📥 Pobieranie mediów z CDN i tworzenie 7 modułów edukacyjnych...') if defined?(log)

# === Katalogi lokalne ===
MEDIA_DIR = Rails.root.join('db/files/media')
ICONS_DIR = Rails.root.join('db/files/media/icons')
DOWNLOAD_DIR = Rails.root.join('tmp/cdn_downloads')
FileUtils.mkdir_p(MEDIA_DIR)
FileUtils.mkdir_p(ICONS_DIR)
FileUtils.mkdir_p(DOWNLOAD_DIR)

# === MIME types ===
MIME_TYPES = {
  '.png' => 'image/png',
  '.jpg' => 'image/jpeg',
  '.jpeg' => 'image/jpeg',
  '.svg' => 'image/svg+xml',
  '.mp4' => 'video/mp4',
  '.webm' => 'video/webm',
  '.srt' => 'text/plain',
  '.vtt' => 'text/vtt',
  '.json' => 'application/json',
  '.pdf' => 'application/pdf'
}.freeze

# === Helper do pobierania plików z CDN ===
def download_from_cdn(url, local_path)
  return local_path if File.exist?(local_path) && File.size(local_path).positive?

  log("   ⬇️  Pobieranie: #{url}") if defined?(log)

  begin
    # rubocop:disable Security/Open -- downloading from trusted CDN (cdn.akademy.edu.pl)
    URI.open(url, 'rb', read_timeout: 300, open_timeout: 30) do |remote|
      # rubocop:enable Security/Open
      File.open(local_path, 'wb') do |local|
        local.write(remote.read)
      end
    end
    local_path
  rescue OpenURI::HTTPError => e
    log("   ❌ HTTP Error: #{e.message} dla #{url}") if defined?(log)
    nil
  rescue StandardError => e
    log("   ❌ Błąd pobierania #{url}: #{e.message}") if defined?(log)
    nil
  end
end

# === Helper do tworzenia uploaded file ===
def create_uploaded_file(path)
  return nil unless path && File.exist?(path)

  ext = File.extname(path).downcase
  mime = MIME_TYPES[ext] || 'application/octet-stream'
  Rack::Test::UploadedFile.new(path, mime)
end

# === Helper do przypinania plików ===
def attach_cdn_file(record, attribute, path)
  return unless path && File.exist?(path)

  uploaded = create_uploaded_file(path)
  return unless uploaded

  record.public_send("#{attribute}=", uploaded)
  record.save!
end

# === Helper do tworzenia ikon SVG z emoji ===
def create_icon_svg(emoji, path)
  return if File.exist?(path)

  svg_content = <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
      <text x="64" y="64" font-size="64" text-anchor="middle" dominant-baseline="central">#{emoji}</text>
    </svg>
  SVG
  File.write(path, svg_content)
end

# === Domyślny payload quizu (fallback) ===
def default_quiz_payload(title)
  {
    'questions' => [
      {
        'id' => 'q1',
        'type' => 'single',
        'text' => "Przykładowe pytanie do #{title}",
        'options' => [
          { 'id' => 'a', 'text' => 'Odpowiedź A' },
          { 'id' => 'b', 'text' => 'Odpowiedź B' },
          { 'id' => 'c', 'text' => 'Odpowiedź C' }
        ],
        'correct' => ['b'],
        'points' => 1
      }
    ],
    'pass_threshold' => 80
  }
end

# === Tworzenie modułów ===
SUBJECTS_CONFIG.each do |subject_config|
  slug = subject_config['slug']
  cdn_folder = subject_config['cdn_folder']

  log("📚 Przetwarzanie: #{subject_config['title']}") if defined?(log)

  # === Subject ===
  subject_uuid = UUIDS.dig('subjects', slug)
  subject = Subject.find_by(id: subject_uuid)

  if subject.nil?
    subject = Subject.new(
      id: subject_uuid,
      school_id: nil,
      title: subject_config['title'],
      slug: slug,
      description: subject_config['description'],
      order_index: subject_config['order_index'],
      color_light: subject_config['color_light'],
      color_dark: subject_config['color_dark']
    )
    subject.save!
  else
    subject.update!(
      title: subject_config['title'],
      description: subject_config['description'],
      order_index: subject_config['order_index'],
      color_light: subject_config['color_light'],
      color_dark: subject_config['color_dark']
    )
  end

  # Ikona dla subjecta
  icon_path = ICONS_DIR.join("#{slug}.svg")
  create_icon_svg(subject_config['icon'], icon_path)
  if (subject.icon.blank? || subject.icon.url.blank?) && File.exist?(icon_path)
    attach_cdn_file(subject, :icon, icon_path)
  end

  # === Unit ===
  unit_uuid = UUIDS.dig('units', slug)
  unit = Unit.find_by(id: unit_uuid)

  if unit.nil?
    unit = Unit.new(
      id: unit_uuid,
      subject: subject,
      title: 'Wprowadzenie',
      order_index: 1
    )
    unit.save!
  else
    unit.update!(subject: subject, title: 'Wprowadzenie', order_index: 1)
  end

  # === LearningModule ===
  module_uuid = UUIDS.dig('modules', slug)
  learning_module = LearningModule.find_by(id: module_uuid)

  single_flow = subject_config['single_flow']

  if learning_module.nil?
    learning_module = LearningModule.new(
      id: module_uuid,
      unit: unit,
      title: subject_config['title'],
      slug: slug,
      order_index: 1,
      single_flow: single_flow,
      published: true
    )
    learning_module.save!
  else
    learning_module.update!(
      unit: unit,
      title: subject_config['title'],
      slug: slug,
      order_index: 1,
      single_flow: single_flow,
      published: true
    )
  end

  # === Contents - tylko jeśli nie istnieją ===
  next if learning_module.contents.any?

  contents = subject_config['contents'] || []
  order_index = 0

  contents.each do |content_config|
    order_index += 1
    content_type = content_config['type']
    title = content_config['title']
    file_name = content_config['file']

    # URL pliku na CDN
    cdn_url = "#{CDN_BASE_URL}/#{cdn_folder}/#{file_name}"
    local_path = DOWNLOAD_DIR.join("#{cdn_folder}_#{file_name}")

    case content_type
    when 'video'
      # Pobierz wideo
      downloaded_video = download_from_cdn(cdn_url, local_path)

      content = Content.new(
        learning_module: learning_module,
        content_type: 'video',
        title: title,
        order_index: order_index,
        duration_sec: content_config['duration_sec'] || 300,
        payload: { subtitles_lang: 'pl' }
      )
      content.save!

      # Załącz wideo
      attach_cdn_file(content, :file, downloaded_video) if downloaded_video

      # Poster (jeśli jest)
      if content_config['poster']
        poster_url = "#{CDN_BASE_URL}/#{cdn_folder}/#{content_config['poster']}"
        poster_path = DOWNLOAD_DIR.join("#{cdn_folder}_#{content_config['poster']}")
        downloaded_poster = download_from_cdn(poster_url, poster_path)
        attach_cdn_file(content, :poster, downloaded_poster) if downloaded_poster
      end

      # Napisy (jeśli są)
      if content_config['subtitles']
        subs_url = "#{CDN_BASE_URL}/#{cdn_folder}/#{content_config['subtitles']}"
        subs_path = DOWNLOAD_DIR.join("#{cdn_folder}_#{content_config['subtitles']}")
        downloaded_subs = download_from_cdn(subs_url, subs_path)
        attach_cdn_file(content, :subtitles, downloaded_subs) if downloaded_subs
      end

    when 'infographic'
      # Pobierz infografikę
      downloaded_infographic = download_from_cdn(cdn_url, local_path)

      content = Content.new(
        learning_module: learning_module,
        content_type: 'infographic',
        title: title,
        order_index: order_index
      )
      content.save!

      attach_cdn_file(content, :file, downloaded_infographic) if downloaded_infographic

    when 'quiz'
      # Pobierz quiz JSON z CDN
      downloaded_quiz = download_from_cdn(cdn_url, local_path)

      quiz_payload = if downloaded_quiz && File.exist?(downloaded_quiz)
                       begin
                         JSON.parse(File.read(downloaded_quiz))
                       rescue JSON::ParserError => e
                         log("   ⚠️  Błąd parsowania JSON quizu: #{e.message}") if defined?(log)
                         default_quiz_payload(title)
                       end
                     else
                       default_quiz_payload(title)
                     end

      Content.create!(
        learning_module: learning_module,
        content_type: 'quiz',
        title: title,
        order_index: order_index,
        payload: quiz_payload
      )
    end
  end

  log("   ✅ Utworzono #{learning_module.contents.count} elementów treści") if defined?(log)
end

# === Cleanup ===
# Opcjonalnie można usunąć pobrane pliki po seedzie:
# FileUtils.rm_rf(DOWNLOAD_DIR)

log('✅ 7 modułów edukacyjnych z CDN zostało załadowanych.') if defined?(log)
