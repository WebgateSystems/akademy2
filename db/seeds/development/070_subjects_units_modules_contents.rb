# frozen_string_literal: true

# DEPRECATED: Ten seed został zastąpiony przez 071_seven_learning_modules.rb
# Usuwamy stare seedy dla "Bezpieczeństwo cyfrowe i e-obywatel" i "Ewakuacja"
# które były specyficzne dla szkoły, a teraz mamy 7 globalnych modułów

return # Skip this seed file - use 071_seven_learning_modules.rb instead

# === Źródła plików (jeśli nie istnieją, tworzymy minimalne placeholdery) ===
MEDIA_DIR = Rails.root.join('db/files/media')
FileUtils.mkdir_p(MEDIA_DIR) unless Dir.exist?(MEDIA_DIR)

VIDEO      = (MEDIA_DIR.join('test.mp4').exist? ? MEDIA_DIR.join('test.mp4') : tmp_file(ext: 'mp4', content: 'mp4 placeholder'))
SUBTITLES  = (MEDIA_DIR.join('test.srt').exist? ? MEDIA_DIR.join('test.srt') : tmp_file(ext: 'srt', content: "1\n00:00:00,000 --> 00:00:01,000\nNapisy testowe\n"))
INFOGRAPH  = (MEDIA_DIR.join('test.png').exist? ? MEDIA_DIR.join('test.png') : tmp_file(ext: 'png', content: "\x89PNG\r\n"))
PDF_DOC    = (MEDIA_DIR.join('test.pdf').exist? ? MEDIA_DIR.join('test.pdf') : tmp_file(ext: 'pdf', content: "%PDF-1.4\n%…minimal\n"))

# === Szkoła docelowa (z wcześniejszych seedów używamy @school_a; w razie czego bierzemy pierwszą) ===
school = defined?(@school_a) && @school_a.present? ? @school_a : School.first!

# Prosty helper do przypinania plików (CarrierWave) z użyciem uploaded_file
def attach_file(record, attribute, path)
  src = path.is_a?(Pathname) ? path.to_s : path
  return unless File.exist?(src)

  record.public_send("#{attribute}=", uploaded_file(src))
  record.save!
end

# === Helper quiz payload (prosty, 2 pytania) ===
QUIZ_PAYLOAD = {
  questions: [
    {
      id: 'q1',
      type: 'single',
      text: 'Phishing to…',
      options: [
        { id: 'a', text: 'rodzaj ryby' },
        { id: 'b', text: 'oszustwo podszywające się pod zaufaną instytucję' }
      ],
      correct: ['b'],
      points: 1
    },
    {
      id: 'q2',
      type: 'multiple',
      text: 'Silne hasło zawiera…',
      options: [
        { id: 'a', text: 'małe i duże litery' },
        { id: 'b', text: 'cyfry' },
        { id: 'c', text: 'znaki specjalne' }
      ],
      correct: %w[a b c],
      points: 1
    }
  ],
  pass_threshold: 80
}.freeze

# ============= Subject 1: „Bezpieczeństwo cyfrowe i e-obywatel” (single-module flow) =============
subject_a = Subject.where(school: school, slug: 'bezpieczenstwo-cyfrowe').first_or_create!(
  title: 'Bezpieczeństwo cyfrowe i e-obywatel',
  order_index: 1
)

unit_a = Unit.where(subject: subject_a, title: 'Wprowadzenie').first_or_create!(order_index: 1)

mod_a = LearningModule.where(unit: unit_a, title: 'Moduł 1').first_or_create!(
  order_index: 1,
  single_flow: true
)

if mod_a.contents.none?
  # Video
  c_video = Content.create!(
    learning_module: mod_a,
    content_type: 'video',
    title: 'Wideo – phishing i higiena haseł',
    order_index: 1,
    payload: { subtitles_lang: 'pl' },
    duration_sec: 60
  )
  attach_file(c_video, :file, VIDEO)
  attach_file(c_video, :subtitles, SUBTITLES)

  # Infografika
  c_info = Content.create!(
    learning_module: mod_a,
    content_type: 'infographic',
    title: 'Infografika – zasady bezpieczeństwa',
    order_index: 2
  )
  attach_file(c_info, :file, INFOGRAPH)

  # Quiz
  Content.create!(
    learning_module: mod_a,
    content_type: 'quiz',
    title: 'Quiz – bezpieczeństwo cyfrowe',
    order_index: 3,
    payload: QUIZ_PAYLOAD
  )
end

# ============= Subject 2: „Ewakuacja” (multi-module → pokaże wybór modułu) =============
subject_b = Subject.where(school: school, slug: 'ewakuacja').first_or_create!(
  title: 'Ewakuacja',
  order_index: 2
)

unit_b = Unit.where(subject: subject_b, title: 'Podstawy').first_or_create!(order_index: 1)

mod_b1 = LearningModule.where(unit: unit_b, title: 'Drogi ewakuacyjne').first_or_create!(
  order_index: 1,
  single_flow: false
)
mod_b2 = LearningModule.where(unit: unit_b, title: 'Punkt zbiórki').first_or_create!(
  order_index: 2,
  single_flow: false
)

[mod_b1, mod_b2].each_with_index do |m, i|
  next unless m.contents.none?

  # Video
  v = Content.create!(
    learning_module: m,
    content_type: 'video',
    title: "Wideo ##{i + 1}",
    order_index: 1,
    duration_sec: 45
  )
  attach_file(v, :file, VIDEO)

  # Infografika
  ig = Content.create!(
    learning_module: m,
    content_type: 'infographic',
    title: "Infografika ##{i + 1}",
    order_index: 2
  )
  attach_file(ig, :file, INFOGRAPH)

  # Quiz
  Content.create!(
    learning_module: m,
    content_type: 'quiz',
    title: "Quiz ##{i + 1}",
    order_index: 3,
    payload: QUIZ_PAYLOAD
  )
end

# Dodatkowy PDF jako materiał w module 1 (karta pracy)
if mod_b1.contents.where(content_type: 'pdf').blank?
  pdf = Content.create!(
    learning_module: mod_b1,
    content_type: 'pdf',
    title: 'Karta pracy – ewakuacja',
    order_index: 4
  )
  attach_file(pdf, :file, PDF_DOC)
end

log('Subjects/Units/Modules/Contents seeded.') if defined?(log)
