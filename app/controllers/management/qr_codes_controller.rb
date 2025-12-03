# frozen_string_literal: true

module Management
  class QrCodesController < Management::BaseController
    def svg
      school = current_school_manager.school
      return head :not_found unless school

      # QR code for teachers to join this school
      qr_url = join_school_url(token: school.join_token)
      theme = params[:theme] || 'light'

      qr = RQRCode::QRCode.new(qr_url)
      qr_color = theme == 'dark' ? '#ffffff' : '#000000'
      svg = qr.as_svg(
        color: qr_color,
        shape_rendering: 'crispEdges',
        module_size: 6,
        standalone: true,
        use_path: true,
        viewbox: true
      )

      render inline: svg, content_type: 'image/svg+xml'
    end

    def png
      school = current_school_manager.school
      return head :not_found unless school

      # QR code for teachers to join this school
      qr_url = join_school_url(token: school.join_token)
      theme = params[:theme] || 'light'
      is_dark = theme == 'dark'

      qr = RQRCode::QRCode.new(qr_url)
      png = qr.as_png(
        color: is_dark ? 'ffffff' : '000000',
        fill: is_dark ? '000000' : 'ffffff',
        size: 500
      )

      send_data png.to_s, type: 'image/png', disposition: 'attachment',
                          filename: "qr-school-#{school.slug}.png"
    end
  end
end
