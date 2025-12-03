class CertificatePdf
  require 'prawn'
  require 'combine_pdf'

  TEMPLATE_PATH = Rails.root.join('app/assets/images/certificates/cert.pdf')

  FONT_MARKER      = Rails.root.join('app/assets/fonts/lumios-marker.ttf')
  FONT_RUBIK_BOLD  = Rails.root.join('app/assets/fonts/Rubik-Bold.ttf')
  FONT_SACRAMENTO  = Rails.root.join('app/assets/fonts/Sacramento-Regular.ttf')

  PAGE_WIDTH = 595

  def self.build(module_name:, student_name:, result:, teacher_name:)
    layer_file = Tempfile.new(['layer', '.pdf'])

    Prawn::Document.generate(layer_file.path, page_size: 'A4') do |pdf|
      setup_fonts(pdf)
      render_text_fields(pdf, module_name, student_name, result, teacher_name)
    end

    merge_with_template(layer_file)
  ensure
    layer_file.close
    layer_file.unlink
  end

  # ============================================
  # PRIVATE METHODS
  # ============================================
  private_class_method def self.setup_fonts(pdf)
    pdf.font_families.update(
      'Marker' => { normal: FONT_MARKER },
      'RubikBold' => { normal: FONT_RUBIK_BOLD },
      'Sacramento' => { normal: FONT_SACRAMENTO }
    )

    # Define helper method inside PDF context
    pdf.define_singleton_method(:center_text) do |text, y_pos:, size:, font:, offset_x: 0|
      font(font, size: size)
      text_width = width_of(text, size: size)
      x_pos = (PAGE_WIDTH - text_width) / 2 + offset_x
      draw_text(text, at: [x_pos, y_pos])
    end
  end

  private_class_method def self.render_text_fields(pdf, module_name, student_name, result, teacher_name)
    render_student_name(pdf, student_name)
    render_module_name(pdf, module_name)
    render_percentage(pdf, result)
    render_teacher_name(pdf, teacher_name)
  end

  # ============================
  # Student Name
  # ============================
  private_class_method def self.render_student_name(pdf, student_name)
    pdf.font('Marker')
    pdf.fill_color '1FA055'

    size = adjust_font_size(pdf, student_name, max: 75, min: 26, allowed: 500)

    pdf.center_text(
      student_name,
      y_pos: 400,
      size: size,
      font: 'Marker',
      offset_x: -35
    )

    pdf.fill_color '000000'
  end

  private_class_method def self.adjust_font_size(pdf, text, max:, min:, allowed:)
    size = max
    size -= 1 while pdf.width_of(text, size: size) > allowed && size > min
    size
  end

  # ============================
  # Module Name
  # ============================
  private_class_method def self.render_module_name(pdf, module_name)
    pdf.center_text(
      module_name,
      y_pos: 315,
      size: 16,
      font: 'RubikBold',
      offset_x: -40
    )
  end

  # ============================
  # Percentage
  # ============================
  private_class_method def self.render_percentage(pdf, result)
    pdf.center_text(
      "#{result}%",
      y_pos: 260,
      size: 16,
      font: 'RubikBold',
      offset_x: -35
    )
  end

  # ============================
  # Teacher Name
  # ============================
  private_class_method def self.render_teacher_name(pdf, teacher_name)
    pdf.font('Sacramento', size: 28)

    base_x = 0              # start position
    base_y = 230
    max_length = 20         # Base length
    coef = 6                # px for each missing character

    name_length = teacher_name.length
    missing     = max_length - name_length

    coef = 5 if name_length > 13
    coef = 7 if name_length == 12

    offset = missing.positive? ? (missing * coef) : 0

    x_position = base_x + offset

    pdf.draw_text teacher_name, at: [x_position, base_y]
  end

  # ============================
  # PDF Merge
  # ============================
  private_class_method def self.merge_with_template(layer_file)
    template = CombinePDF.load(TEMPLATE_PATH)
    layer    = CombinePDF.load(layer_file.path)

    final = CombinePDF.new
    final << (template.pages[0] << layer.pages[0])
    final.to_pdf
  end
end
