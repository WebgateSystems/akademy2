# frozen_string_literal: true

desc 'Run E2E tests. Usage: rake test / rake test[superadmin] / rake test[superadmin,gui]'
task :test, [:name, :mode] do |_t, args|
  name = args[:name]
  gui_mode = args[:mode] == 'gui'

  if name.present?
    run_single_test(name, headless: !gui_mode)
  else
    run_all_tests(headless: !gui_mode)
  end
end

desc 'Run ALL E2E tests with visible browser'
task 'test:gui' do
  run_all_tests(headless: false)
end

def run_all_tests(headless:)
  mode = headless ? 'headless' : 'GUI (browser visible)'
  puts "🧪 Running ALL E2E tests (#{mode})..."
  puts '=' * 50

  ENV['E2E_HEADLESS'] = headless.to_s
  success = system('node e2e/run-all.js')
  exit(1) unless success
end

def run_single_test(test_name, headless:)
  test_file = find_test_file(test_name)

  unless test_file
    puts "❌ Test not found: #{test_name}"
    puts "\nAvailable tests:"
    list_available_tests
    exit(1)
  end

  mode = headless ? 'headless' : 'GUI'
  puts "🧪 Running: #{File.basename(test_file)} (#{mode})..."
  puts '=' * 50

  ENV['E2E_HEADLESS'] = headless.to_s
  success = system("node #{test_file}")
  exit(1) unless success
end

def find_test_file(test_name)
  patterns = [
    "e2e/tests/#{test_name}.test.js",
    "e2e/tests/#{test_name}-menu.test.js",
    "e2e/tests/#{test_name.tr('_', '-')}.test.js",
    "e2e/tests/#{test_name.tr('_', '-')}-menu.test.js"
  ]

  patterns.each do |pattern|
    return pattern if File.exist?(pattern)
  end

  Dir.glob("e2e/tests/*#{test_name}*.test.js").first
end

def list_available_tests
  Dir.glob('e2e/tests/*.test.js').each do |file|
    name = File.basename(file, '.test.js').sub(/-menu$/, '')
    puts "  - #{name}"
  end
end
