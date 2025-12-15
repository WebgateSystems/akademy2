# frozen_string_literal: true

# Check if staff from this seed already exist (by email pattern)
return if User.where('email LIKE ?', 'nauczyciel.sp35.%@akademy.local').exists?

log('Create Staff and Classes for SP35...')

pwd = 'devpass!'
teacher_role = Role.find_by!(key: 'teacher')
principal_role = Role.find_by!(key: 'principal')

# Find school SP35
school = School.find_by!(slug: 'sp35-gdynia')

# NOTE: Academic year 2025/2026 is set as current for this school
# Classes are NOT created per requirements - only teachers

# Teachers from https://www.sp35gdynia.pl/a/nauczyciele
# Wychowawcy z klasami + pozostali nauczyciele
teachers_data = [
  # Dyrekcja
  { first_name: 'Agnieszka', last_name: 'Kilichowska', subjects: ['matematyka'], role: :principal, position: 'Dyrektor Szkoły' },
  { first_name: 'Marlena', last_name: 'Reszke', subjects: ['matematyka'], role: :vice_principal, position: 'Wicedyrektor Szkoły' },

  # Wychowawcy klas
  { first_name: 'Ewelina', last_name: 'Linde', subjects: ['edukacja wczesnoszkolna', 'język angielski'], homeroom_class: '1a' },
  { first_name: 'Joanna', last_name: 'Wielgos', subjects: ['edukacja wczesnoszkolna'], homeroom_class: '1b sportowa' },
  { first_name: 'Agnieszka', last_name: 'Janczyńska', subjects: ['edukacja wczesnoszkolna'], homeroom_class: '2a' },
  { first_name: 'Joanna', last_name: 'Topolewska', subjects: ['edukacja wczesnoszkolna'], homeroom_class: '2b sportowa' },
  { first_name: 'Hanna', last_name: 'Piaszczyńska', subjects: ['edukacja wczesnoszkolna'], homeroom_class: '3a' },
  { first_name: 'Wioleta', last_name: 'Bellwon', subjects: ['edukacja wczesnoszkolna'], homeroom_class: '3b sportowa' },
  { first_name: 'Barbara', last_name: 'Kupczak', subjects: ['muzyka'], homeroom_class: '4a' },
  { first_name: 'Katarzyna', last_name: 'Mrozowska', subjects: ['historia', 'wiedza o społeczeństwie'], homeroom_class: '4b' },
  { first_name: 'Daria', last_name: 'Poborska', subjects: ['matematyka'], homeroom_class: '5a' },
  { first_name: 'Joanna', last_name: 'Leszczyńska', subjects: [], homeroom_class: '5b' },
  { first_name: 'Kajetan', last_name: 'Kalinowski', subjects: ['wychowanie fizyczne'], homeroom_class: '6a' },
  { first_name: 'Żaneta', last_name: 'Dusza', subjects: %w[przyroda geografia], homeroom_class: '6b' },
  { first_name: 'Anna', last_name: 'Kaczmarek', subjects: %w[przyroda biologia], homeroom_class: '7a' },
  { first_name: 'Monika', last_name: 'Tusk-Turzyńska', subjects: ['język angielski'], homeroom_class: '7b' },
  { first_name: 'Joanna', last_name: 'Morąg', subjects: ['język angielski'], homeroom_class: '7c' },
  { first_name: 'Jolanta', last_name: 'Zaremba', subjects: ['język angielski', 'historia'], homeroom_class: '8a' },
  { first_name: 'Marek', last_name: 'Strzelczyk', subjects: ['matematyka', 'informatyka', 'wychowanie fizyczne'] },

  # Pozostali nauczyciele
  { first_name: 'Dawid', last_name: 'Antoszewski', subjects: ['edukacja dla bezpieczeństwa'] },
  { first_name: 'Renata', last_name: 'Badtke', subjects: ['matematyka'] },
  { first_name: 'Anna', last_name: 'Bartusz-Kościukiewicz', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Ewa', last_name: 'Bludnik', subjects: ['logopeda'] },
  { first_name: 'Bartosz', last_name: 'Bławat', subjects: ['wychowanie fizyczne'] },
  { first_name: 'Marlena', last_name: 'Bohn', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Alicja', last_name: 'Brzozowska', subjects: ['chemia'] },
  { first_name: 'Justyna', last_name: 'Dobrowolska', subjects: ['język polski'] },
  { first_name: 'Małgorzata', last_name: 'Filipowicz', subjects: ['psycholog'] },
  { first_name: 'Jolanta', last_name: 'Galant-Nazar', subjects: ['fizyka'] },
  { first_name: 'Kamil', last_name: 'Gołdowski', subjects: ['język polski'] },
  { first_name: 'Izabela', last_name: 'Halk', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Kamila', last_name: 'Hebda', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Beata', last_name: 'Hen', subjects: ['język angielski'] },
  { first_name: 'Olga', last_name: 'Ibrahim', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Ewelina', last_name: 'Ignasiak', subjects: ['język polski'] },
  { first_name: 'Urszula', last_name: 'Janusz', subjects: ['religia'] },
  { first_name: 'Aleksandra', last_name: 'Jaremin', subjects: ['biblioteka'] },
  { first_name: 'Mirosława', last_name: 'Kąc', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Mariusz', last_name: 'Krawiec', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Krzysztof', last_name: 'Morąg', subjects: ['język angielski', 'język niemiecki'] },
  { first_name: 'Joanita', last_name: 'Nawrocka', subjects: ['biblioteka'] },
  { first_name: 'Janina', last_name: 'Ostałowska', subjects: ['matematyka'] },
  { first_name: 'Klaudia', last_name: 'Pawlak', subjects: ['świetlica'] },
  { first_name: 'Barbara', last_name: 'Picheta', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Galina', last_name: 'Pienszka', subjects: ['świetlica'] },
  { first_name: 'Sylwia', last_name: 'Pietrzak', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Magdalena', last_name: 'Przygodzka', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Anna', last_name: 'Szczęch', subjects: ['psycholog specjalny'] },
  { first_name: 'Magda', last_name: 'Tabor', subjects: ['świetlica'] },
  { first_name: 'Dagmara', last_name: 'Tarkowska', subjects: ['świetlica'] },
  { first_name: 'Agata', last_name: 'Tażbierska', subjects: ['język niemiecki'] },
  { first_name: 'Aldona', last_name: 'Tomaśko-Pilarska', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Anna', last_name: 'Trąbka', subjects: ['wychowanie fizyczne'] },
  { first_name: 'Kamila', last_name: 'Trejman-Grzelak', subjects: ['pedagog'] },
  { first_name: 'Agnieszka', last_name: 'Wabik', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Anna', last_name: 'Wieczorek', subjects: ['świetlica'] },
  { first_name: 'Dominika', last_name: 'Winiecka', subjects: ['wychowanie fizyczne'] },
  { first_name: 'Dorota', last_name: 'Witecka', subjects: %w[plastyka technika] }
]

# Create teachers
teachers_data.each_with_index do |teacher_data, index|
  email = "nauczyciel.sp35.#{index + 1}@akademy.local"

  user = User.create!(
    email: email,
    password: pwd,
    password_confirmation: pwd,
    first_name: teacher_data[:first_name],
    last_name: teacher_data[:last_name],
    locale: 'pl',
    school: school,
    confirmed_at: Time.current,
    phone: "+48#{rand(500_000_000..999_999_999)}",
    metadata: {
      subjects: teacher_data[:subjects] || [],
      position: teacher_data[:position],
      homeroom_class: teacher_data[:homeroom_class]
    }
  )

  # Assign role based on position
  case teacher_data[:role]
  when :principal
    UserRole.create!(user: user, role: principal_role, school: school)
  when :vice_principal
    UserRole.create!(user: user, role: teacher_role, school: school)
  else
    UserRole.create!(user: user, role: teacher_role, school: school)
  end
end

# NOTE: Classes are NOT created for SP35 per requirements
# Only academic year 2025/2026 is set as current
# Teacher homeroom assignments are stored in metadata for future use

log("Created #{teachers_data.length} staff members for SP35 (no classes generated)")
