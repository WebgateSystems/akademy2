# frozen_string_literal: true

namespace :student_videos do
  desc 'Regenerate thumbnails for all student videos'
  task regenerate_thumbnails: :environment do
    puts 'Regenerating thumbnails for student videos...'

    StudentVideo.find_each do |video|
      next if video.file.blank?

      video_path = video.file.path
      next unless video_path && File.exist?(video_path)

      begin
        processor = VideoProcessor.new(video_path)
        # Force reload movie to get dimensions
        processor.send(:load_movie!)
        thumbnail_path = processor.generate_thumbnail

        if thumbnail_path && File.exist?(thumbnail_path)
          # Remove old thumbnail
          video.remove_thumbnail! if video.thumbnail.present?

          # Attach new thumbnail
          File.open(thumbnail_path) do |thumb_file|
            video.thumbnail = thumb_file
            video.save!
          end

          FileUtils.rm_f(thumbnail_path)
          puts "  ✓ Regenerated thumbnail for video #{video.id} (#{video.title})"
        else
          puts "  ✗ Failed to generate thumbnail for video #{video.id}"
        end
      rescue StandardError => e
        puts "  ✗ Error processing video #{video.id}: #{e.message}"
      end
    end

    puts 'Done!'
  end

  desc 'Reprocess all videos (duration + thumbnail)'
  task reprocess: :environment do
    puts 'Reprocessing all student videos...'

    StudentVideo.find_each do |video|
      next if video.file.blank?

      ProcessVideoJob.perform_later(video.id)
      puts "  → Enqueued ProcessVideoJob for video #{video.id}"
    end

    puts 'Done! Jobs enqueued.'
  end
end
