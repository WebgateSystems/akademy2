# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentVideo, type: :model do
  describe 'YouTube deletion enqueue on destroy' do
    it 'enqueues DeleteYoutubeVideoJob when youtube_id is present' do
      DeleteYoutubeVideoJob.clear

      video = create(:student_video, :approved, youtube_id: 'yt_abc', youtube_url: 'https://youtu.be/yt_abc')
      allow(video).to receive(:remove_file_from_disk) # avoid touching filesystem in this spec

      expect do
        video.destroy
      end.to change(DeleteYoutubeVideoJob.jobs, :size).by(1)

      expect(DeleteYoutubeVideoJob.jobs.last['args']).to eq([video.id, 'yt_abc'])
    end

    it 'does not enqueue when youtube_id is blank' do
      DeleteYoutubeVideoJob.clear

      video = create(:student_video, :approved, youtube_id: nil, youtube_url: nil)
      allow(video).to receive(:remove_file_from_disk)

      expect do
        video.destroy
      end.not_to change(DeleteYoutubeVideoJob.jobs, :size)
    end
  end
end
