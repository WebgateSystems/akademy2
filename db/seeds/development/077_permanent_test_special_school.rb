# frozen_string_literal: true

# Permanent test school for mobile app testing (Google/Apple review)
# Based on "Włatcy móch" animated series
# All emails and phones are UNVERIFIED to prevent SMS/email sending
# IMPORTANT: We use skip_confirmation_notification! to prevent ANY email sending

return if School.exists?(id: '77777777-3d96-492d-900e-777777777777')

log('Create Permanent Special School "Włatcy Móch"...')

spec_logo = Rails.root.join('db/files/schools/spec.png')

# =============================================================================
# SCHOOL
# =============================================================================
school = School.new(
  id: '77777777-3d96-492d-900e-777777777777',
  name: 'Szkoła specjalna im. Włatców Móch Bartka Kędzierskiego',
  slug: 'szkola-specjalna-wlatcow',
  address: 'ul. Świętego ducha 48/50. Amen',
  postcode: '00-071',
  city: 'Warszawa',
  phone: '+48226952901',
  homepage: 'https://pl.wikipedia.org/wiki/W%C5%82atcy_m%C3%B3ch'
)
school.logo = uploaded_file(spec_logo) if File.exist?(spec_logo)
school.save!

# =============================================================================
# ROLES
# =============================================================================
principal_role = Role.find_by!(key: 'principal')
school_manager_role = Role.find_by!(key: 'school_manager')
teacher_role = Role.find_by!(key: 'teacher')
student_role = Role.find_by!(key: 'student')

# =============================================================================
# PASSWORDS
# =============================================================================
adult_password = 'devpass!'
student_pin = '0000'

# =============================================================================
# HELPER: Create user WITHOUT any email/SMS notifications
# This is critical - we must NEVER send any emails or SMS from test data!
# =============================================================================
def create_user_without_notifications(attrs)
  user = User.new(attrs)

  # Skip all Devise email notifications
  user.skip_confirmation_notification! if user.respond_to?(:skip_confirmation_notification!)
  user.skip_reconfirmation! if user.respond_to?(:skip_reconfirmation!)

  user.save!

  # After save, mark that confirmation email was "already sent" to prevent future sends
  # Using update_columns to bypass all callbacks and validations
  user.update_columns(
    confirmed_at: nil, # Keep unconfirmed
    confirmation_sent_at: Time.current # Pretend email was sent
  )

  user
end

# =============================================================================
# HELPER: Random adult birthday (1970-1996)
# =============================================================================
def random_adult_birthday
  Date.new(rand(1970..1996), rand(1..12), rand(1..28))
end

# =============================================================================
# ACADEMIC YEAR 2025/2026
# =============================================================================
academic_year_value = '2025/2026'

# Create and set as current academic year for this school
AcademicYear.find_or_create_by!(school: school, year: academic_year_value) do |ay|
  ay.is_current = true
end

# =============================================================================
# CLASSES: 2B and 4B
# =============================================================================
log('  Creating classes 2B and 4B...')

class_2b = SchoolClass.create!(
  school: school,
  name: '2B',
  year: academic_year_value,
  qr_token: SecureRandom.uuid,
  metadata: {}
)

class_4b = SchoolClass.create!(
  school: school,
  name: '4B',
  year: academic_year_value,
  qr_token: SecureRandom.uuid,
  metadata: {}
)

# =============================================================================
# SCHOOL ADMINISTRATION
# =============================================================================
log('  Creating school administration...')

# Dyrektor: Bartek Kędzierski (also homeroom teacher for 4B)
bartus = create_user_without_notifications(
  email: 'bartus@wlatcy.edu.pl',
  password: adult_password,
  password_confirmation: adult_password,
  first_name: 'Bartek',
  last_name: 'Kędzierski',
  locale: 'pl',
  school: school,
  phone: '+48997998999',
  birthdate: random_adult_birthday,
  metadata: { phone_verified: false, title: 'mgr' }
)
UserRole.create!(user: bartus, role: principal_role, school: school)
UserRole.create!(user: bartus, role: teacher_role, school: school)
TeacherSchoolEnrollment.create!(teacher: bartus, school: school, status: 'approved')

# Assign Bartus as homeroom teacher for 4B
TeacherClassAssignment.create!(
  teacher: bartus,
  school_class: class_4b,
  role: 'homeroom'
)

# Manager szkolny: Michał Lorenc (also staff in 2B)
misio = create_user_without_notifications(
  email: 'misio@wlatcy.edu.pl',
  password: adult_password,
  password_confirmation: adult_password,
  first_name: 'Michał',
  last_name: 'Lorenc',
  locale: 'pl',
  school: school,
  phone: '+48411222441',
  birthdate: random_adult_birthday,
  metadata: { phone_verified: false, title: 'mgr' }
)
UserRole.create!(user: misio, role: school_manager_role, school: school)
UserRole.create!(user: misio, role: teacher_role, school: school)
TeacherSchoolEnrollment.create!(teacher: misio, school: school, status: 'approved')

# Assign Misio as staff in 2B
TeacherClassAssignment.create!(
  teacher: misio,
  school_class: class_2b,
  role: 'staff'
)

# Manager szkolny 2: Marcin Krzyżanowski
krzyz = create_user_without_notifications(
  email: 'krzyz@wlatcy.edu.pl',
  password: adult_password,
  password_confirmation: adult_password,
  first_name: 'Marcin',
  last_name: 'Krzyżanowski',
  locale: 'pl',
  school: school,
  phone: '+48511222551',
  birthdate: random_adult_birthday,
  metadata: { phone_verified: false, title: 'mgr' }
)
UserRole.create!(user: krzyz, role: school_manager_role, school: school)

# =============================================================================
# TEACHERS
# =============================================================================
log('  Creating teachers...')

# Pani Frał - homeroom 2B, staff in 4B
pani_fral = create_user_without_notifications(
  email: 'teachertest@gmail.com',
  password: adult_password,
  password_confirmation: adult_password,
  first_name: 'Pani',
  last_name: 'Frał',
  locale: 'pl',
  school: school,
  phone: '+48211333112',
  birthdate: random_adult_birthday,
  metadata: { phone_verified: false, title: 'mgr', subjects: %w[matematyka biologia religia] }
)
UserRole.create!(user: pani_fral, role: teacher_role, school: school)
TeacherSchoolEnrollment.find_or_create_by!(teacher: pani_fral, school: school) do |e|
  e.status = 'approved'
end

# Homeroom for 2B
TeacherClassAssignment.create!(
  teacher: pani_fral,
  school_class: class_2b,
  role: 'homeroom'
)
# Staff in 4B
TeacherClassAssignment.create!(
  teacher: pani_fral,
  school_class: class_4b,
  role: 'staff'
)

# Iwona Higienistka - staff in 2B and 4B
iwona = create_user_without_notifications(
  email: 'bielska@wlatcy.edu.pl',
  password: adult_password,
  password_confirmation: adult_password,
  first_name: 'Iwona',
  last_name: 'Higienistka',
  locale: 'pl',
  school: school,
  phone: '+48112112112',
  birthdate: random_adult_birthday,
  metadata: { phone_verified: false, title: 'mgr', subjects: %w[bhp ratownictwo] }
)
UserRole.create!(user: iwona, role: teacher_role, school: school)
TeacherSchoolEnrollment.find_or_create_by!(teacher: iwona, school: school) do |e|
  e.status = 'approved'
end

TeacherClassAssignment.create!(teacher: iwona, school_class: class_2b, role: 'staff')
TeacherClassAssignment.create!(teacher: iwona, school_class: class_4b, role: 'staff')

# Tomasz Leśniak - no class assignment
tomcio = create_user_without_notifications(
  email: 'tomcio@wlatcy.edu.pl',
  password: adult_password,
  password_confirmation: adult_password,
  first_name: 'Tomasz',
  last_name: 'Leśniak',
  locale: 'pl',
  school: school,
  phone: '+48311222331',
  birthdate: random_adult_birthday,
  metadata: { phone_verified: false, title: 'mgr', subjects: %w[astronomia chemia fizyka] }
)
UserRole.create!(user: tomcio, role: teacher_role, school: school)
TeacherSchoolEnrollment.find_or_create_by!(teacher: tomcio, school: school) do |e|
  e.status = 'approved'
end

# Update class metadata with homeroom teachers
class_2b.update!(metadata: { homeroom_teacher_id: pani_fral.id })
class_4b.update!(metadata: { homeroom_teacher_id: bartus.id })

# =============================================================================
# STUDENTS 2B (birthday 2016-2017)
# =============================================================================
log('  Creating students for 2B...')

students_2b = [
  { first_name: 'Czesio', last_name: 'Opania', email: 'czesio@wlatcy.edu.pl', phone: '+48123234345' },
  { first_name: 'Jarosław', last_name: 'Anusiak', email: 'anusiak@wlatcy.edu.pl', phone: '+48000111002' },
  { first_name: 'Piotr', last_name: 'Maślana', email: 'maslana@wlatcy.edu.pl', phone: '+48000111003' },
  { first_name: 'Konstantyn', last_name: 'Konieczko', email: 'konieczko@wlatcy.edu.pl', phone: '+48000111004' },
  { first_name: 'Junior', last_name: 'Kędzierski', email: 'kedzierski@wlatcy.edu.pl', phone: '+48000111005' },
  { first_name: 'Antoni', last_name: 'Zajkowski', email: 'zajkos@wlatcy.edu.pl', phone: '+48000111006' },
  { first_name: 'Andżelika', last_name: 'Star', email: 'angelika@wlatcy.edu.pl', phone: '+48000111007' },
  { first_name: 'Karol', last_name: 'Karolina', email: 'karol@wlatcy.edu.pl', phone: '+48000111008' },
  { first_name: 'Maria', last_name: 'Golińska', email: 'masza@wlatcy.edu.pl', phone: '+48000111009' },
  { first_name: 'Basia', last_name: 'Cywka', email: 'basia@wlatcy.edu.pl', phone: '+48000111010' },
  { first_name: 'Tadeusz', last_name: 'Grabski', email: 'tadek@wlatcy.edu.pl', phone: '+48000111011' },
  { first_name: 'Magdalena', last_name: 'Rakowska', email: 'madzia@wlatcy.edu.pl', phone: '+48000111012' },
  { first_name: 'Mirosław', last_name: 'Kulesza', email: 'miro@wlatcy.edu.pl', phone: '+48000111014' }
]

students_2b.each do |data|
  user = create_user_without_notifications(
    email: data[:email],
    password: student_pin,
    password_confirmation: student_pin,
    first_name: data[:first_name],
    last_name: data[:last_name],
    locale: 'pl',
    school: school,
    phone: data[:phone],
    birthdate: Date.new(rand(2016..2017), rand(1..12), rand(1..28)),
    metadata: { phone_verified: false }
  )

  UserRole.create!(user: user, role: student_role, school: school)

  StudentClassEnrollment.create!(
    student_id: user.id,
    school_class: class_2b,
    status: 'approved',
    joined_at: Time.current
  )
end

# =============================================================================
# STUDENTS 4B (birthday 2014-2015)
# =============================================================================
log('  Creating students for 4B...')

students_4b = [
  { first_name: 'Michał', last_name: 'Kwiatkowski', email: 'kwiatek@wlatcy.edu.pl', phone: '+48222111001' },
  { first_name: 'Michał', last_name: 'Głowacki', email: 'glowacki@wlatcy.edu.pl', phone: '+48222111002' },
  { first_name: 'Bartosz', last_name: 'Boberek', email: 'bobr@wlatcy.edu.pl', phone: '+48222111003' },
  { first_name: 'Jarosław', last_name: 'Adamczyk', email: 'jarozbaw@wlatcy.edu.pl', phone: '+48222111004' },
  { first_name: 'Marek', last_name: 'Frąckowiak', email: 'mario@wlatcy.edu.pl', phone: '+48222111005' },
  { first_name: 'Krystyna', last_name: 'Bielska', email: 'krysia@wlatcy.edu.pl', phone: '+48222111006' },
  { first_name: 'Telewizja', last_name: 'Polsat', email: 'emisja@wlatcy.edu.pl', phone: '+48222111007' }
]

students_4b.each do |data|
  user = create_user_without_notifications(
    email: data[:email],
    password: student_pin,
    password_confirmation: student_pin,
    first_name: data[:first_name],
    last_name: data[:last_name],
    locale: 'pl',
    school: school,
    phone: data[:phone],
    birthdate: Date.new(rand(2014..2015), rand(1..12), rand(1..28)),
    metadata: { phone_verified: false }
  )

  UserRole.create!(user: user, role: student_role, school: school)

  StudentClassEnrollment.create!(
    student_id: user.id,
    school_class: class_4b,
    status: 'approved',
    joined_at: Time.current
  )
end

# =============================================================================
# SUMMARY
# =============================================================================
log('Created Włatcy Móch school with:')
log('  - 3 school administrators (1 principal, 2 managers)')
log('  - 3 teachers')
log("  - #{students_2b.count} students in 2B")
log("  - #{students_4b.count} students in 4B")
log('  - All emails and phones are UNVERIFIED (no SMS/email sending)')
log("  - Adult password: #{adult_password}")
log("  - Student PIN: #{student_pin}")
