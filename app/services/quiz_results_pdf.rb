# frozen_string_literal: true

# Service class for generating PDF reports of quiz results
# rubocop:disable Metrics/ClassLength
class QuizResultsPdf
  require 'prawn'
  require 'prawn/table'

  FONT_RUBIK_BOLD = Rails.root.join('app/assets/fonts/Rubik-Bold.ttf')

  # rubocop:disable Metrics/ParameterLists
  def self.build(subject:, school_class:, school:, students:, questions:, student_answers:,
                 completion_rate:, average_score:, distribution:, teacher:)
    Prawn::Document.new(page_size: 'A4', page_layout: :landscape, margin: 30) do |pdf|
      setup_fonts(pdf)
      render_header(pdf, subject, school_class, school, teacher)
      pdf.move_down 15
      render_statistics(pdf, completion_rate, average_score, distribution)
      pdf.move_down 20
      render_results_table(pdf, students, questions, student_answers)
      render_footer(pdf)
    end.render
  end
  # rubocop:enable Metrics/ParameterLists

  class << self
    private

    def setup_fonts(pdf)
      pdf.font_families.update(
        'Rubik' => { normal: FONT_RUBIK_BOLD.to_s, bold: FONT_RUBIK_BOLD.to_s }
      )
      pdf.font 'Rubik'
    end

    def render_header(pdf, subject, school_class, school, teacher)
      pdf.font 'Rubik', size: 16
      pdf.text "Wyniki quizu: #{subject.title}", align: :center
      pdf.font 'Rubik', size: 10
      pdf.move_down 8
      pdf.text build_header_info(school, school_class, teacher), align: :center, color: '666666'
    end
    # rubocop:enable Metrics/AbcSize

    def build_header_info(school, school_class, teacher)
      info = []
      info << "Szkoła: #{school&.name}" if school
      info << "Klasa: #{school_class.name}"
      info << "Rok: #{school&.current_academic_year_value || '2025/2026'}"
      info << "Nauczyciel: #{teacher.first_name} #{teacher.last_name}"
      info << "Data wydruku: #{Time.current.strftime('%d.%m.%Y %H:%M')}"
      info.join('  •  ')
    end

    def render_statistics(pdf, completion_rate, average_score, distribution)
      pdf.font 'Rubik', size: 9
      stats_data = [build_stats_row(completion_rate, average_score, distribution)]

      pdf.table(stats_data, width: pdf.bounds.width, cell_style: { align: :center, padding: 8 }) do
        cells.borders = [:bottom]
        cells.border_width = 0.5
        cells.border_color = 'CCCCCC'
      end
    end

    def build_stats_row(completion_rate, average_score, distribution)
      [
        stat_cell('Completion rate', "#{completion_rate}%"),
        stat_cell('Average performance', "#{average_score} pkt"),
        stat_cell('No results', "#{distribution&.dig(:no_results) || 0}%"),
        stat_cell('Bad results (<50%)', "#{distribution&.dig(:bad_results) || 0}%"),
        stat_cell('Average (50-75%)', "#{distribution&.dig(:average_results) || 0}%"),
        stat_cell('Great results (≥75%)', "#{distribution&.dig(:great_results) || 0}%")
      ]
    end

    def stat_cell(label, value)
      "#{label}\n#{value}"
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def render_results_table(pdf, students, _questions, student_answers)
      pdf.font 'Rubik', size: 8
      data = build_results_data(students, student_answers)
      col_widths = calculate_column_widths(pdf.bounds.width)

      pdf.table(data, header: true, width: pdf.bounds.width, column_widths: col_widths) do |table|
        table.row(0).font_style = :bold
        table.row(0).background_color = 'E8E8E8'
        table.cells.padding = [4, 3]
        table.cells.align = :center
        table.cells.size = 8
        table.column(0).align = :left

        # Color correct/incorrect answers
        (1...data.length).each do |row_idx|
          (1..10).each do |col_idx|
            cell_val = data[row_idx][col_idx]
            table.row(row_idx).column(col_idx).text_color = '1FA055' if cell_val == '✓'
            table.row(row_idx).column(col_idx).text_color = 'CC3333' if cell_val == '✗'
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def build_results_data(students, student_answers)
      header = ['Nazwisko i imię'] + (1..10).map { |n| "P#{n}" } + ['Wynik']
      data = [header]
      students.each { |student| data << build_student_row(student, student_answers) }
      data
    end

    def build_student_row(student, student_answers)
      row = ["#{student.last_name} #{student.first_name}"]
      (1..10).each { |q_num| row << answer_symbol(student_answers&.dig(student.id, q_num)) }
      row << calculate_score(student_answers&.dig(student.id))
      row
    end

    def answer_symbol(answer_data)
      return '-' if answer_data.nil?

      answer_data[:correct] ? '✓' : '✗'
    end

    def calculate_score(answers)
      return '0 pkt' unless answers

      correct_count = answers.values.compact.count { |a| a[:correct] }
      "#{correct_count * 10} pkt"
    end

    def calculate_column_widths(available_width)
      name_col = available_width * 0.25
      result_col = available_width * 0.08
      question_col = (available_width - name_col - result_col) / 10.0

      col_widths = { 0 => name_col, 11 => result_col }
      (1..10).each { |i| col_widths[i] = question_col }
      col_widths
    end

    def render_footer(pdf)
      pdf.number_pages 'Strona <page> z <total>',
                       at: [pdf.bounds.right - 100, 0],
                       width: 100,
                       align: :right,
                       size: 8,
                       color: '999999'
    end
  end
end
# rubocop:enable Metrics/ClassLength
