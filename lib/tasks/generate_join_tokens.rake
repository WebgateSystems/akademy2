# frozen_string_literal: true

namespace :join_tokens do
  desc 'Generate join_token for existing schools and school_classes that do not have one'
  task generate: :environment do
    puts '=' * 60
    puts 'Generating join_tokens for existing records...'
    puts '=' * 60

    # Generate tokens for schools
    schools_updated = 0
    School.where(join_token: nil).find_each do |school|
      # Format: xxxx-xxxx-xxxxxxxxxxxx (last 3 segments of UUID)
      loop do
        token = SecureRandom.uuid.split('-').last(3).join('-')
        next if School.exists?(join_token: token)

        school.update_column(:join_token, token)
        schools_updated += 1
        puts "  School ##{school.id} (#{school.name}): #{token}"
        break
      end
    end

    # Generate tokens for school classes
    classes_updated = 0
    SchoolClass.where(join_token: nil).find_each do |school_class|
      # Format: xxxxxxxx-xxxx-xxxx (first 3 segments of UUID)
      loop do
        token = SecureRandom.uuid.split('-').first(3).join('-')
        next if SchoolClass.exists?(join_token: token)

        school_class.update_column(:join_token, token)
        classes_updated += 1
        puts "  Class ##{school_class.id} (#{school_class.name}): #{token}"
        break
      end
    end

    puts '=' * 60
    puts "Done! Updated #{schools_updated} schools and #{classes_updated} classes."
    puts '=' * 60
  end

  desc 'Show all join_tokens for schools and classes'
  task list: :environment do
    puts '=' * 60
    puts 'Schools join_tokens (format: xxxx-xxxx-xxxxxxxxxxxx)'
    puts '=' * 60
    School.find_each do |school|
      status = school.join_token.presence || '(missing!)'
      puts "  #{school.name}: #{status}"
    end

    puts
    puts '=' * 60
    puts 'School Classes join_tokens (format: xxxxxxxx-xxxx-xxxx)'
    puts '=' * 60
    SchoolClass.includes(:school).find_each do |school_class|
      status = school_class.join_token.presence || '(missing!)'
      puts "  #{school_class.school.name} - #{school_class.name}: #{status}"
    end
  end

  desc 'Regenerate ALL join_tokens (use with caution!)'
  task regenerate_all: :environment do
    puts 'WARNING: This will regenerate ALL join_tokens!'
    puts 'Existing links/QR codes will stop working!'
    puts
    print 'Type "YES" to continue: '
    confirmation = $stdin.gets.chomp

    unless confirmation == 'YES'
      puts 'Aborted.'
      exit
    end

    puts
    puts '=' * 60
    puts 'Regenerating all join_tokens...'
    puts '=' * 60

    School.find_each do |school|
      loop do
        token = SecureRandom.uuid.split('-').last(3).join('-')
        next if School.where.not(id: school.id).exists?(join_token: token)

        school.update_column(:join_token, token)
        puts "  School ##{school.id} (#{school.name}): #{token}"
        break
      end
    end

    SchoolClass.find_each do |school_class|
      loop do
        token = SecureRandom.uuid.split('-').first(3).join('-')
        next if SchoolClass.where.not(id: school_class.id).exists?(join_token: token)

        school_class.update_column(:join_token, token)
        puts "  Class ##{school_class.id} (#{school_class.name}): #{token}"
        break
      end
    end

    puts '=' * 60
    puts 'Done!'
    puts '=' * 60
  end
end
