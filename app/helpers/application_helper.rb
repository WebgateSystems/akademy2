module ApplicationHelper
  def app_version
    "App version: ##{AppIdService.version}"
  end

  # Generate QR code SVG for a given URL
  # rubocop:disable Rails/OutputSafety
  def render_qr_svg(url, size: 150, dark_color: '000000', light_color: 'ffffff')
    qr = RQRCode::QRCode.new(url)
    svg = qr.as_svg(
      color: dark_color,
      fill: light_color,
      shape_rendering: 'crispEdges',
      module_size: 4,
      viewbox: true,
      use_path: true
    )
    # Inject width/height into SVG
    svg.sub('<svg ', "<svg width=\"#{size}\" height=\"#{size}\" ").html_safe
  end
  # rubocop:enable Rails/OutputSafety
end
