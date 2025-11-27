# frozen_string_literal: true

module Management
  class QrCodesController < Management::BaseController
    def svg
      school = current_school_manager.school
      return head :not_found unless school

      qr_url = register_teacher_url(school_slug: school.slug)
      theme = params[:theme] || 'light'
      is_dark = theme == 'dark'

      qr = RQRCode::QRCode.new(qr_url)
      svg = qr.as_svg(
        color: is_dark ? 'ffffff' : '000000',
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

      qr_url = register_teacher_url(school_slug: school.slug)
      theme = params[:theme] || 'light'
      is_dark = theme == 'dark'

      qr = RQRCode::QRCode.new(qr_url)
      png = qr.as_png(
        color: is_dark ? 'ffffff' : '000000',
        fill: is_dark ? '000000' : 'ffffff',
        size: 500
      )

      send_data png.to_s, type: 'image/png', disposition: 'attachment',
                          filename: "qr-code-#{school.slug}.png"
    end
  end
end
