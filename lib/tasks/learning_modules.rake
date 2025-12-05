# frozen_string_literal: true

namespace :learning_modules do
  desc 'Generate slugs for learning modules that do not have one'
  task generate_slugs: :environment do
    count = 0
    LearningModule.where(slug: nil).find_each do |lm|
      lm.save! # This will trigger generate_slug callback
      count += 1
      puts "Generated slug for: #{lm.title} -> #{lm.slug}"
    end
    puts "Done! Generated #{count} slugs."
  end
end
