# frozen_string_literal: true

# Check if teachers from this seed already exist (by email pattern)
return if User.where('email LIKE ?', 'nauczyciel.sp51.%@akademy.local').exists?

log('Create Teachers and Classes for SP51...')

pwd = 'devpass!'
teacher_role = Role.find_by!(key: 'teacher')
principal_role = Role.find_by!(key: 'principal')

# Find school SP51
school = School.find_by!(slug: 'sp51-gdynia')

# Ensure academic year 2025/2026 exists
academic_year = '2025/2026'

# Teachers from https://sp51gdynia.pl/nauczyciele,47,pl
# Stan na 1.09.2025
teachers_data = [
  # Dyrekcja
  { first_name: 'Olga', last_name: 'Labudda', title: 'dr', role: :principal, subjects: %w[chemia matematyka] },
  { first_name: 'Magdalena', last_name: 'Kubiak', title: 'mgr', role: :vice_principal, subjects: ['język angielski', 'edukacja wczesnoszkolna'] },

  # Specjaliści
  { first_name: 'Joanna', last_name: 'Konkiel', title: 'mgr', subjects: ['pedagog szkolny'] },
  { first_name: 'Aleksandra', last_name: 'Guzik', title: 'mgr', subjects: ['psycholog szkolny'] },
  { first_name: 'Agata', last_name: 'Sosnowska', title: 'mgr', subjects: ['pedagog specjalny'] },

  # Bibliotekarze
  { first_name: 'Anna', last_name: 'Mytkowska', title: 'mgr', subjects: ['biblioteka'] },
  { first_name: 'Janusz', last_name: 'Żurawski', title: 'mgr', subjects: ['biblioteka'] },

  # Język polski
  { first_name: 'Joanna', last_name: 'Antczak-Sokołowska', title: 'mgr', subjects: ['język polski'] },
  { first_name: 'Alicja', last_name: 'Jankowska', title: 'mgr', subjects: ['język polski', 'język angielski'] },
  { first_name: 'Sylwia', last_name: 'Praska', title: 'mgr', subjects: ['język polski'] },
  { first_name: 'Dorota', last_name: 'Nowakowska', title: 'mgr', subjects: ['język polski'] },

  # Język angielski
  { first_name: 'Marta', last_name: 'Kalinowska', title: 'mgr', subjects: ['język angielski'] },
  { first_name: 'Magdalena', last_name: 'Necel', title: 'mgr', subjects: ['język angielski', 'historia'] },
  { first_name: 'Amelia', last_name: 'Ciemierkiewicz', title: 'mgr', subjects: ['język angielski'] },

  # Języki obce
  { first_name: 'Marianna', last_name: 'Grudziecka', title: 'mgr', subjects: ['język niemiecki', 'fizyka', 'matematyka'] },
  { first_name: 'Agnieszka', last_name: 'Ossowska', title: 'mgr', subjects: ['język francuski', 'edukacja wczesnoszkolna'] },

  # Przedmioty przyrodnicze
  { first_name: 'Lucyna', last_name: 'Lewandowska', title: 'mgr', subjects: %w[biologia przyroda geografia] },

  # Matematyka i informatyka
  { first_name: 'Katarzyna', last_name: 'Kowalewska', title: 'mgr', subjects: ['matematyka'] },
  { first_name: 'Małgorzata', last_name: 'Muchowska', title: 'mgr', subjects: ['matematyka'] },
  { first_name: 'Bożena', last_name: 'Bencer', title: 'mgr', subjects: ['informatyka'] },
  { first_name: 'Danuta', last_name: 'Maliszewska', title: 'mgr', subjects: ['informatyka'] },

  # Przedmioty artystyczne i techniczne
  { first_name: 'Magdalena', last_name: 'Kapka', title: 'mgr', subjects: %w[plastyka technika] },
  { first_name: 'Oksana', last_name: 'Levytska', title: 'mgr', subjects: ['muzyka'] },

  # Wychowanie fizyczne
  { first_name: 'Małgorzata', last_name: 'Frącek', title: 'mgr', subjects: ['wychowanie fizyczne'] },
  { first_name: 'Krzysztof', last_name: 'Niedźwiedź', title: 'mgr', subjects: ['wychowanie fizyczne', 'edukacja zdrowotna'] },
  { first_name: 'Martyna', last_name: 'Nosewicz', title: 'mgr', subjects: ['wychowanie fizyczne', 'EDB'], class: '4A' },
  { first_name: 'Liliana', last_name: 'Wanta', title: 'mgr', subjects: ['wychowanie fizyczne', 'edukacja zdrowotna', 'świetlica'] },

  # Religia
  { first_name: 'Adam', last_name: 'Hrubiszewski', title: 'ks.', subjects: ['religia'] },

  # Edukacja wczesnoszkolna
  { first_name: 'Sylwia', last_name: 'Cimiengo', title: 'mgr', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Paulina', last_name: 'Wruk', title: 'mgr', subjects: ['edukacja wczesnoszkolna', 'świetlica'] },
  { first_name: 'Ewa', last_name: 'Kurasz', title: 'mgr', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Zofia', last_name: 'Granos', title: 'mgr', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Alicja', last_name: 'Wodecka', title: 'mgr', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Aleksandra', last_name: 'Panasiewicz', title: 'mgr', subjects: ['edukacja wczesnoszkolna', 'świetlica'] },

  # Wspomaganie wczesnoszkolne
  { first_name: 'Paulina', last_name: 'Czarska', title: 'mgr', subjects: ['wspomaganie wczesnoszkolne'] },
  { first_name: 'Paulina', last_name: 'Styrbicka', title: 'mgr', subjects: ['wspomaganie wczesnoszkolne'] },
  { first_name: 'Alicja', last_name: 'Byczyk', title: 'mgr', subjects: ['wspomaganie wczesnoszkolne', 'świetlica'] },
  { first_name: 'Izabela', last_name: 'Meller', title: 'mgr', subjects: ['wspomaganie wczesnoszkolne'] },
  { first_name: 'Karolina', last_name: 'Szmytkowska-Michałek', title: 'mgr', subjects: ['wspomaganie wczesnoszkolne'] },

  # Świetlica
  { first_name: 'Anna', last_name: 'Misiak-Krasicka', title: 'mgr', subjects: ['świetlica'] },
  { first_name: 'Grażyna', last_name: 'Godlewska', title: 'mgr', subjects: ['świetlica'] },
  { first_name: 'Anna', last_name: 'Rekowska', title: 'mgr', subjects: ['świetlica'] },
  { first_name: 'Joanna', last_name: 'Gawron', title: 'mgr', subjects: ['świetlica'] }
]

# Create teachers
created_teachers = {}
teachers_data.each_with_index do |teacher_data, index|
  email = "nauczyciel.sp51.#{index + 1}@akademy.local"

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
      title: teacher_data[:title],
      subjects: teacher_data[:subjects] || [],
      class: teacher_data[:class]
    }
  )

  # Assign role based on position
  case teacher_data[:role]
  when :principal
    UserRole.create!(user: user, role: principal_role, school: school)
  when :vice_principal
    UserRole.create!(user: user, role: teacher_role, school: school)
    # Could add vice_principal role if exists
  else
    UserRole.create!(user: user, role: teacher_role, school: school)
  end

  # Store for class assignment
  created_teachers[teacher_data[:class]] = user if teacher_data[:class]
end

# Create classes for 2025/2026
# Klasy: 4A, 4B, 4C, 5A, 5B, 6A, 6B, 7A, 7B, 7C, 8A, 8B
classes = %w[4A 4B 4C 5A 5B 6A 6B 7A 7B 7C 8A 8B]

classes.each do |class_name|
  SchoolClass.create!(
    school: school,
    name: class_name,
    year: academic_year,
    qr_token: SecureRandom.uuid,
    metadata: {
      homeroom_teacher_id: created_teachers[class_name]&.id
    }
  )
end

log("Created #{teachers_data.length} teachers and #{classes.length} classes for SP51")
