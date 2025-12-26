# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteYoutubeVideoJob, type: :job do
  subject(:job) { described_class.new }

  let(:student_video_id) { 'sv_123' }
  let(:youtube_id) { 'yt_123' }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  it 'logs success result' do
    service = instance_double(YoutubeDeleteService, call: :deleted)
    allow(YoutubeDeleteService).to receive(:new).with(youtube_id: youtube_id).and_return(service)

    job.perform(student_video_id, youtube_id)

    expect(Rails.logger).to have_received(:info).with(/\[YouTubeDelete\]\[deleted\] StudentVideo##{student_video_id}/)
  end

  it 're-raises errors to trigger retry' do
    allow(YoutubeDeleteService).to receive(:new).and_raise(StandardError, 'boom')

    expect { job.perform(student_video_id, youtube_id) }.to raise_error(StandardError, 'boom')
    expect(Rails.logger).to have_received(:error).with(/\[YouTubeDelete\]\[fail\]/)
  end
end
