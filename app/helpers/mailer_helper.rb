# frozen_string_literal: true

module MailerHelper
  # Returns base64 encoded logo for embedding in emails
  # This ensures the logo displays even when external images are blocked
  def embedded_logo_data_uri
    logo_path = Rails.root.join('public/logo_full-mailing.svg')
    return '' unless File.exist?(logo_path)

    svg_content = File.read(logo_path)
    base64_content = Base64.strict_encode64(svg_content)
    "data:image/svg+xml;base64,#{base64_content}"
  end
end
