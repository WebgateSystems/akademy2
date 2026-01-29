# frozen_string_literal: true

namespace :certificates do
  desc 'Regenerate all certificate PDFs (preserves filenames and paths)'
  task regenerate: :environment do
    puts 'Regenerating all certificate PDFs...'
    puts ''

    certificates = Certificate.includes(quiz_result: [{ learning_module: { unit: :subject } }, { user: :school }])
    total = certificates.count

    if total.zero?
      puts 'No certificates found.'
      exit
    end

    puts "Found #{total} certificates to regenerate."
    puts ''

    success_count = 0
    error_count = 0
    start_time = Time.current

    certificates.find_each.with_index do |certificate, index|
      progress = ((index + 1).to_f / total * 100).round(1)
      print "\r[#{progress.to_s.rjust(5)}%] Processing certificate #{index + 1}/#{total}..."

      begin
        regenerate_certificate(certificate)
        success_count += 1
      rescue StandardError => e
        error_count += 1
        puts ''
        puts "  ✗ Error regenerating certificate #{certificate.id}: #{e.message}"
      end
    end

    elapsed = (Time.current - start_time).round(1)

    puts ''
    puts ''
    puts '=' * 50
    puts 'Regeneration complete!'
    puts "  ✓ Success: #{success_count}"
    puts "  ✗ Errors:  #{error_count}" if error_count.positive?
    puts "  Time:     #{elapsed}s"
    puts '=' * 50
  end

  desc 'Regenerate certificate PDF for a specific certificate ID'
  task :regenerate_one, [:certificate_id] => :environment do |_t, args|
    certificate = Certificate.find_by(id: args[:certificate_id])

    if certificate.nil?
      puts "Certificate not found: #{args[:certificate_id]}"
      exit 1
    end

    puts "Regenerating certificate #{certificate.id}..."
    regenerate_certificate(certificate)
    puts '  ✓ Done!'
  end

  def regenerate_certificate(certificate)
    data = extract_certificate_data(certificate)
    pdf_binary = generate_pdf_binary(data)
    write_pdf(certificate, pdf_binary)
  end

  def extract_certificate_data(certificate)
    quiz_result = certificate.quiz_result
    subject = fetch_subject(quiz_result)
    user = quiz_result.user
    teacher = find_teacher_for_certificate(user)

    {
      subject_title: subject.title,
      student_name: "#{user.first_name} #{user.last_name}",
      score: quiz_result.score,
      teacher_name: "#{teacher.first_name} #{teacher.last_name}"
    }
  end

  def fetch_subject(quiz_result)
    quiz_result.learning_module.unit.subject
  end

  def generate_pdf_binary(data)
    CertificatePdf.build(
      module_name: data[:subject_title],
      student_name: data[:student_name],
      result: data[:score],
      teacher_name: data[:teacher_name]
    )
  end

  def write_pdf(certificate, pdf_binary)
    current_path = certificate.pdf&.path

    if current_path && File.exist?(current_path)
      File.binwrite(current_path, pdf_binary)
    else
      write_pdf_via_carrierwave(certificate, pdf_binary)
    end
  end

  def write_pdf_via_carrierwave(certificate, pdf_binary)
    tmp = Tempfile.new(['cert', '.pdf'])
    tmp.binmode
    tmp.write(pdf_binary)
    tmp.rewind

    certificate.pdf = tmp
    certificate.save!
  ensure
    tmp&.close
  end

  def find_teacher_for_certificate(student)
    year = student.school&.current_academic_year_value
    klass = student.school_classes.find_by(year: year)

    klass&.main_teacher || klass&.teachers&.first || placeholder_teacher
  end

  def placeholder_teacher
    Struct.new(:first_name, :last_name).new('John', 'Doe')
  end
end
