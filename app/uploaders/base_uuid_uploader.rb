class BaseUuidUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    parts = model.id.to_s.scan(/.{1,2}/).first(2).join('/')
    "public/uploads/#{model.class.name.underscore}/#{mounted_as}/#{parts}/#{model.id}"
  end

  def filename
    return if original_filename.blank?

    @filename ||= "#{SecureRandom.uuid}#{File.extname(original_filename).downcase}"
  end

  def extension_allowlist
    %w[jpg jpeg png svg pdf mp4 webm srt vtt]
  end
end
