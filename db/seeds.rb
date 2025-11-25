# frozen_string_literal: true

require 'rack/test'

class Factory
  require 'factory_bot'
  include FactoryBot::Syntax::Methods
end

def log(message) = puts "→ #{message}"

MIME = {
  '.png' => 'image/png',
  '.jpg' => 'image/jpeg',
  '.jpeg' => 'image/jpeg',
  '.svg' => 'image/svg+xml',
  '.mp4' => 'video/mp4',
  '.webm' => 'video/webm',
  '.pdf' => 'application/pdf',
  '.srt' => 'text/plain',
  '.vtt' => 'text/vtt'
}.freeze

def uploaded_file(path)
  ext = File.extname(path).downcase
  Rack::Test::UploadedFile.new(path, MIME[ext] || 'application/octet-stream')
end

def tmp_file(ext:, content: 'seed file')
  dir = Rails.root.join('tmp/seeds')
  FileUtils.mkdir_p(dir)
  path = dir.join("#{SecureRandom.hex}.#{ext}")
  File.write(path, content)
  path
end

Dir[Rails.root.join('db', 'seeds', Rails.env, '*.rb')].sort.each { |seed| load seed }
