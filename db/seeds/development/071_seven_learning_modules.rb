# frozen_string_literal: true

# Seeds dla 7 modułów edukacyjnych z zahardkodowanymi UUID
# Każdy moduł ma swój kolor, ikonę i przykładowe materiały

# Guard clause - sprawdzamy czy subjects mają już ikony jako pliki (CarrierWave)
# Jeśli ikony są stringami (emoji), pozwalamy na reseed
existing_subjects = Subject.where(school_id: nil)
if existing_subjects.exists?
  # Sprawdzamy czy wszystkie mają ikony jako pliki
  all_have_file_icons = existing_subjects.all? do |s|
    s.icon.present? && s.icon.is_a?(CarrierWave::Uploader::Base) && s.icon.url.present?
  end
  return if all_have_file_icons # Skip jeśli wszystkie mają już pliki
end

log('Create 7 Learning Modules with fixed UUIDs...') if defined?(log)

# === Helper do przypinania plików ===
def attach_file(record, attribute, path)
  src = path.is_a?(Pathname) ? path.to_s : path
  return unless File.exist?(src)

  record.public_send("#{attribute}=", uploaded_file(src))
  record.save!
end

# === Katalogi dla plików ===
MEDIA_DIR = Rails.root.join('db/files/media')
ICONS_DIR = Rails.root.join('db/files/media/icons')
FileUtils.mkdir_p(MEDIA_DIR) unless Dir.exist?(MEDIA_DIR)
FileUtils.mkdir_p(ICONS_DIR) unless Dir.exist?(ICONS_DIR)

# === Zahardkodowane UUID dla spójności ===
SUBJECT_UUIDS = {
  'polska-i-swiat' => '11111111-1111-1111-1111-111111111111',
  'kryzys-klimatyczny' => '22222222-2222-2222-2222-222222222222',
  'reakcja-na-alarmy' => '33333333-3333-3333-3333-333333333333',
  'ewakuacja' => '44444444-4444-4444-4444-444444444444',
  'pierwsza-pomoc' => '55555555-5555-5555-5555-555555555555',
  'cyber-bezpieczenstwo' => '66666666-6666-6666-6666-666666666666',
  'bezpieczne-zachowanie' => '77777777-7777-7777-7777-777777777777'
}.freeze

UNIT_UUIDS = {
  'polska-i-swiat' => 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'kryzys-klimatyczny' => 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'reakcja-na-alarmy' => 'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'ewakuacja' => 'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'pierwsza-pomoc' => 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
  'cyber-bezpieczenstwo' => 'ffffffff-ffff-ffff-ffff-ffffffffffff',
  'bezpieczne-zachowanie' => '10101010-1010-1010-1010-101010101010'
}.freeze

MODULE_UUIDS = {
  'polska-i-swiat' => 'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1',
  'kryzys-klimatyczny' => 'b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2',
  'reakcja-na-alarmy' => 'c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3',
  'ewakuacja' => 'd4d4d4d4-d4d4-d4d4-d4d4-d4d4d4d4d4d4',
  'pierwsza-pomoc' => 'e5e5e5e5-e5e5-e5e5-e5e5-e5e5e5e5e5e5',
  'cyber-bezpieczenstwo' => 'f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6',
  'bezpieczne-zachowanie' => '17171717-1717-1717-1717-171717171717'
}.freeze

# === Definicje 7 modułów ===
MODULES = [
  {
    slug: 'polska-i-swiat',
    title: 'Polska i świat',
    icon: '🇵🇱',
    color_light: '#4A90E2',
    color_dark: '#206EC9',
    order_index: 1,
    youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', # Przykładowy link
    quiz: {
      questions: [
        {
          id: 'q1',
          type: 'single',
          text: 'Stolicą Polski jest:',
          options: [
            { id: 'a', text: 'Kraków' },
            { id: 'b', text: 'Warszawa' },
            { id: 'c', text: 'Gdańsk' }
          ],
          correct: ['b'],
          points: 1
        },
        {
          id: 'q2',
          type: 'multiple',
          text: 'Które kraje sąsiadują z Polską?',
          options: [
            { id: 'a', text: 'Niemcy' },
            { id: 'b', text: 'Czechy' },
            { id: 'c', text: 'Słowacja' },
            { id: 'd', text: 'Ukraina' }
          ],
          correct: %w[a b c d],
          points: 1
        },
        {
          id: 'q3',
          type: 'single',
          text: 'Ile województw ma Polska?',
          options: [
            { id: 'a', text: '14' },
            { id: 'b', text: '16' },
            { id: 'c', text: '18' }
          ],
          correct: ['b'],
          points: 1
        }
      ],
      pass_threshold: 80
    }
  },
  {
    slug: 'kryzys-klimatyczny',
    title: 'Kryzys klimatyczny',
    icon: '🌍',
    color_light: '#6CC24A',
    color_dark: '#529C35',
    order_index: 2,
    youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    quiz: {
      questions: [
        {
          id: 'q1',
          type: 'single',
          text: 'Głównym gazem cieplarnianym jest:',
          options: [
            { id: 'a', text: 'Tlen' },
            { id: 'b', text: 'Dwutlenek węgla' },
            { id: 'c', text: 'Azot' }
          ],
          correct: ['b'],
          points: 1
        },
        {
          id: 'q2',
          type: 'multiple',
          text: 'Jak możemy przeciwdziałać zmianom klimatu?',
          options: [
            { id: 'a', text: 'Oszczędzanie energii' },
            { id: 'b', text: 'Używanie transportu publicznego' },
            { id: 'c', text: 'Sadzenie drzew' }
          ],
          correct: %w[a b c],
          points: 1
        }
      ],
      pass_threshold: 80
    }
  },
  {
    slug: 'reakcja-na-alarmy',
    title: 'Reakcja na alarmy',
    icon: '🔔',
    color_light: '#FFD74B',
    color_dark: '#F4B400',
    order_index: 3,
    youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    quiz: {
      questions: [
        {
          id: 'q1',
          type: 'single',
          text: 'Co należy zrobić gdy usłyszysz alarm pożarowy?',
          options: [
            { id: 'a', text: 'Zostać w miejscu' },
            { id: 'b', text: 'Natychmiast ewakuować się' },
            { id: 'c', text: 'Sprawdzić co się dzieje' }
          ],
          correct: ['b'],
          points: 1
        },
        {
          id: 'q2',
          type: 'single',
          text: 'Alarm bombowy sygnalizowany jest przez:',
          options: [
            { id: 'a', text: 'Ciągły sygnał dźwiękowy' },
            { id: 'b', text: 'Przerywany sygnał dźwiękowy' },
            { id: 'c', text: 'Komunikaty głosowe' }
          ],
          correct: ['c'],
          points: 1
        }
      ],
      pass_threshold: 80
    }
  },
  {
    slug: 'ewakuacja',
    title: 'Ewakuacja',
    icon: '🏃‍♂️',
    color_light: '#F56CA0',
    color_dark: '#C9356A',
    order_index: 4,
    youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    quiz: {
      questions: [
        {
          id: 'q1',
          type: 'single',
          text: 'Podczas ewakuacji należy:',
          options: [
            { id: 'a', text: 'Biec jak najszybciej' },
            { id: 'b', text: 'Iść spokojnie, nie panikować' },
            { id: 'c', text: 'Zabierać wszystkie rzeczy' }
          ],
          correct: ['b'],
          points: 1
        },
        {
          id: 'q2',
          type: 'multiple',
          text: 'Gdzie znajdują się drogi ewakuacyjne?',
          options: [
            { id: 'a', text: 'Główne korytarze' },
            { id: 'b', text: 'Schody ewakuacyjne' },
            { id: 'c', text: 'Winda' }
          ],
          correct: %w[a b],
          points: 1
        }
      ],
      pass_threshold: 80
    }
  },
  {
    slug: 'pierwsza-pomoc',
    title: 'Pierwsza pomoc',
    icon: '❤️‍🩹',
    color_light: '#FF9B42',
    color_dark: '#EF6C00',
    order_index: 5,
    youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    quiz: {
      questions: [
        {
          id: 'q1',
          type: 'single',
          text: 'Numer alarmowy w Polsce to:',
          options: [
            { id: 'a', text: '997' },
            { id: 'b', text: '998' },
            { id: 'c', text: '999' }
          ],
          correct: ['c'],
          points: 1
        },
        {
          id: 'q2',
          type: 'single',
          text: 'Podstawowe czynności pierwszej pomocy to:',
          options: [
            { id: 'a', text: 'Wezwanie pomocy, sprawdzenie oddechu, uciskanie klatki' },
            { id: 'b', text: 'Podanie wody, okrycie kocem' },
            { id: 'c', text: 'Przeniesienie poszkodowanego' }
          ],
          correct: ['a'],
          points: 1
        }
      ],
      pass_threshold: 80
    }
  },
  {
    slug: 'cyber-bezpieczenstwo',
    title: 'Cyber-bezpieczeństwo',
    icon: '💻',
    color_light: '#4A90E2',
    color_dark: '#206EC9',
    order_index: 6,
    youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    quiz: {
      questions: [
        {
          id: 'q1',
          type: 'single',
          text: 'Phishing to:',
          options: [
            { id: 'a', text: 'Rodzaj ryby' },
            { id: 'b', text: 'Oszustwo internetowe' },
            { id: 'c', text: 'Program komputerowy' }
          ],
          correct: ['b'],
          points: 1
        },
        {
          id: 'q2',
          type: 'multiple',
          text: 'Silne hasło powinno zawierać:',
          options: [
            { id: 'a', text: 'Małe i duże litery' },
            { id: 'b', text: 'Cyfry' },
            { id: 'c', text: 'Znaki specjalne' }
          ],
          correct: %w[a b c],
          points: 1
        }
      ],
      pass_threshold: 80
    }
  },
  {
    slug: 'bezpieczne-zachowanie',
    title: 'Bezpieczne zachowanie',
    icon: '🛡️',
    color_light: '#6CC24A',
    color_dark: '#529C35',
    order_index: 7,
    youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    quiz: {
      questions: [
        {
          id: 'q1',
          type: 'single',
          text: 'Nieznajomym osobom:',
          options: [
            { id: 'a', text: 'Można ufać' },
            { id: 'b', text: 'Nie należy podawać danych osobowych' },
            { id: 'c', text: 'Można iść z nimi' }
          ],
          correct: ['b'],
          points: 1
        },
        {
          id: 'q2',
          type: 'single',
          text: 'Bezpieczne zachowanie to:',
          options: [
            { id: 'a', text: 'Uważność i ostrożność' },
            { id: 'b', text: 'Ufność do wszystkich' },
            { id: 'c', text: 'Ignorowanie zasad' }
          ],
          correct: ['a'],
          points: 1
        }
      ],
      pass_threshold: 80
    }
  }
].freeze

# === Tworzenie ikon jako placeholder PNG ===
def create_icon_placeholder(icon_path, emoji)
  return if File.exist?(icon_path)

  # Tworzymy prosty SVG z emoji jako placeholder
  svg_content = <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
      <rect width="128" height="128" fill="#f0f0f0" rx="16"/>
      <text x="64" y="80" font-size="64" text-anchor="middle">#{emoji}</text>
    </svg>
  SVG
  File.write(icon_path, svg_content)
end

# === Tworzenie placeholder dla infografiki ===
def create_infographic_placeholder(path, title)
  return if File.exist?(path)

  svg_content = <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600">
      <rect width="800" height="600" fill="#ffffff"/>
      <rect x="50" y="50" width="700" height="500" fill="#f5f5f5" stroke="#ddd" stroke-width="2" rx="8"/>
      <text x="400" y="300" font-size="32" text-anchor="middle" fill="#333">#{title}</text>
      <text x="400" y="350" font-size="18" text-anchor="middle" fill="#666">Infografika</text>
    </svg>
  SVG
  File.write(path, svg_content)
end

# === Tworzenie placeholder dla napisów ===
def create_subtitles_placeholder(path)
  return if File.exist?(path)

  srt_content = <<~SRT
    1
    00:00:00,000 --> 00:00:05,000
    Przykładowe napisy

    2
    00:00:05,000 --> 00:00:10,000
    Drugi fragment napisów
  SRT
  File.write(path, srt_content)
end

# === Tworzenie modułów ===
MODULES.each do |module_data|
  subject_uuid = SUBJECT_UUIDS[module_data[:slug]]
  unit_uuid = UNIT_UUIDS[module_data[:slug]]
  module_uuid = MODULE_UUIDS[module_data[:slug]]

  # Subject (globalny, bez school_id) - z zahardkodowanym UUID
  subject = Subject.find_by(id: subject_uuid)
  if subject.nil?
    subject = Subject.new(
      id: subject_uuid,
      school_id: nil, # Global subject
      title: module_data[:title],
      slug: module_data[:slug],
      order_index: module_data[:order_index],
      color_light: module_data[:color_light],
      color_dark: module_data[:color_dark]
    )
    subject.save!
  else
    subject.update!(
      title: module_data[:title],
      slug: module_data[:slug],
      order_index: module_data[:order_index],
      color_light: module_data[:color_light],
      color_dark: module_data[:color_dark]
    )
  end

  # Ikona dla subjecta - uploadujemy jako plik SVG przez CarrierWave
  # Tworzymy prosty SVG z emoji jako placeholder jeśli plik nie istnieje
  icon_path = ICONS_DIR.join("#{module_data[:slug]}.svg")
  create_icon_placeholder(icon_path, module_data[:icon])
  # Upload ikony tylko jeśli jeszcze nie ma przypisanej ikony
  attach_file(subject, :icon, icon_path) if (subject.icon.blank? || subject.icon.url.blank?) && File.exist?(icon_path)

  # Unit - z zahardkodowanym UUID
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
    unit.update!(
      subject: subject,
      title: 'Wprowadzenie',
      order_index: 1
    )
  end

  # LearningModule - z zahardkodowanym UUID
  # Nazwa modułu = nazwa przedmiotu (bo jest tylko jeden moduł per subject)
  learning_module = LearningModule.find_by(id: module_uuid)
  if learning_module.nil?
    learning_module = LearningModule.new(
      id: module_uuid,
      unit: unit,
      title: module_data[:title],
      slug: module_data[:slug],
      order_index: 1,
      single_flow: true,
      published: true
    )
    learning_module.save!
  else
    learning_module.update!(
      unit: unit,
      title: module_data[:title],
      slug: module_data[:slug],
      order_index: 1,
      single_flow: true,
      published: true
    )
  end

  # Contents - tylko jeśli nie istnieją
  next if learning_module.contents.any?

  # Video Content
  video_content = Content.new(
    learning_module: learning_module,
    content_type: 'video',
    title: "Wideo – #{module_data[:title]}",
    order_index: 1,
    payload: { subtitles_lang: 'pl' },
    duration_sec: 300, # 5 minut
    youtube_url: module_data[:youtube_url]
  )
  video_content.save!

  # Placeholder dla napisów
  subtitles_path = MEDIA_DIR.join("#{module_data[:slug]}_subtitles.srt")
  create_subtitles_placeholder(subtitles_path)
  attach_file(video_content, :subtitles, subtitles_path) if File.exist?(subtitles_path)

  # Infographic Content
  infographic_path = MEDIA_DIR.join("#{module_data[:slug]}_infographic.svg")
  create_infographic_placeholder(infographic_path, module_data[:title])
  infographic_content = Content.new(
    learning_module: learning_module,
    content_type: 'infographic',
    title: "Infografika – #{module_data[:title]}",
    order_index: 2
  )
  infographic_content.save!
  attach_file(infographic_content, :file, infographic_path) if File.exist?(infographic_path)

  # Quiz Content
  Content.create!(
    learning_module: learning_module,
    content_type: 'quiz',
    title: "Quiz – #{module_data[:title]}",
    order_index: 3,
    payload: module_data[:quiz]
  )
end

log('7 Learning Modules seeded successfully.') if defined?(log)
