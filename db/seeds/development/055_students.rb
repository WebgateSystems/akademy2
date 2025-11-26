# frozen_string_literal: true

return if User.joins(:roles).where(roles: { key: 'student' }).exists?

log('Create Students...')

pwd = 'devpass!'
student_role = Role.find_by!(key: 'student')

# Polish first names
male_names = %w[Adam Adrian Aleksander Bartosz Błażej Damian Daniel Dawid Filip Jakub Jan Kacper Kamil Karol Krystian Krzysztof Łukasz Maciej Marcin Mateusz Michał Mikołaj Nikodem Oskar Patryk Paweł Piotr Przemysław Rafał Sebastian Szymon Tomasz Wiktor]
female_names = %w[Aleksandra Alicja Amelia Anna Antonina Barbara Blanka Dagmara Dominika Emilia Ewa Gabriela Hanna Iga Izabela Julia Justyna Karolina Kinga Klaudia Laura Lena Magdalena Małgorzata Maria Martyna Natalia Nikola Oliwia Patrycja Paulina Sara Wiktoria Zofia Zuzanna]

# Polish last names
last_names = %w[Nowak Kowalski Wiśniewski Wójcik Kowalczyk Kamiński Lewandowski Zieliński Szymański Woźniak Dąbrowski Kozłowski Jabłoński Mazur Krawczyk Piotrowski Grabowski Nowakowski Pawłowski Michalski Nowicki Adamczyk Dudek Zając Wieczorek Jabłoński Król Majewski Olszewski Stępień Jaworski Malinowski Pawlak Witkowski Walczak Stepień Górski Rutkowski Michalak Sikora Ostrowski Baran Duda Szewczyk Turek Pietrzak Wróbel Marciniak Jasiński Zawadzki Bąk Jakubowski Sadowski Dudek Bednarek Włodarczyk Błaszczyk Lis]

# Get all classes for both schools
classes = SchoolClass.all

classes.each do |school_class|
  # Random number of students between 16 and 26
  student_count = rand(16..26)

  # Determine how many students will be pending (2-3)
  pending_count = rand(2..3)

  student_count.times do |index|
    # Randomly choose gender
    is_female = rand < 0.5

    first_name = is_female ? female_names.sample : male_names.sample
    last_name = last_names.sample

    # Generate email
    school_slug = school_class.school.slug.presence || "school#{school_class.school_id}"
    email = "uczen.#{school_slug}.#{school_class.name.downcase.gsub(/[^a-z0-9]/, '')}.#{index + 1}@akademy.local"

    # Generate phone number for student (needed for PIN login)
    phone = "+48#{rand(500_000_000..999_999_999)}"

    # Generate PIN (4 digits)
    pin = format('%04d', rand(0..9999))

    # Create user
    user = User.create!(
      email: email,
      password: pin,
      password_confirmation: pin,
      first_name: first_name,
      last_name: last_name,
      locale: 'pl',
      school: school_class.school,
      phone: phone,
      confirmed_at: Time.current,
      birthdate: Date.new(rand(2010..2015), rand(1..12), rand(1..28)),
      metadata: {
        gender: is_female ? 'female' : 'male',
        pin: pin
      }
    )

    # Assign student role
    UserRole.create!(user: user, role: student_role, school: school_class.school)

    # Enroll in class
    # First pending_count students will be pending, rest will be approved
    status = index < pending_count ? 'pending' : 'approved'

    StudentClassEnrollment.create!(
      student_id: user.id,
      school_class: school_class,
      status: status,
      joined_at: status == 'approved' ? Time.current : nil
    )
  end

  log("  Created #{student_count} students for class #{school_class.name} (#{school_class.school.name})")
end
