# frozen_string_literal: true

# Check if staff from this seed already exist (by email pattern)
return if User.where('email LIKE ?', '%@sp12gdynia.edu.pl').exists?

log('Create Staff for SP12...')

pwd = 'devpass!'
teacher_role = Role.find_by!(key: 'teacher')
principal_role = Role.find_by!(key: 'principal')

# Find school SP12
school = School.find_by!(slug: 'sp12-gdynia')

# Teachers from https://sp12gdynia.pl/nauczyciele/ - rok szkolny 2025/2026
teachers_data = [
  # Dyrekcja
  { first_name: 'Maria', last_name: 'Śmiełowska-Bohn', email: 'maria.bohn@sp12gdynia.edu.pl', subjects: ['informatyka'], role: :principal },
  { first_name: 'Magdalena', last_name: 'Bukowska', email: 'magdalena.bukowska@sp12gdynia.edu.pl', subjects: %w[matematyka fizyka informatyka], role: :vice_principal },
  { first_name: 'Daria', last_name: 'Derkowska', email: 'daria.derkowska@sp12gdynia.edu.pl', subjects: ['historia', 'wiedza o społeczeństwie', 'doradztwo zawodowe'], role: :vice_principal },

  # Nauczyciele
  { first_name: 'Tomasz', last_name: 'Baraniak', email: 'tomasz.baraniak@sp12gdynia.edu.pl', subjects: ['wychowanie fizyczne', 'edukacja zdrowotna'] },
  { first_name: 'Małgorzata', last_name: 'Bergau-Jankowska', email: 'malgorzata.jankowska@sp12gdynia.edu.pl', subjects: ['język angielski'] },
  { first_name: 'Ewa', last_name: 'Biernacka', email: 'ewa.biernacka@sp12gdynia.edu.pl', subjects: ['geografia'] },
  { first_name: 'Małgorzata', last_name: 'Brochocka', email: 'malgorzata.brochocka@sp12gdynia.edu.pl', subjects: %w[przyroda biologia biblioteka] },
  { first_name: 'Barbara', last_name: 'Chojnacka', email: 'barbara.chojnacka@sp12gdynia.edu.pl', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Paulina', last_name: 'Chojnowska', email: 'paulina.chojnowska@sp12gdynia.edu.pl', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Katarzyna', last_name: 'Chrapkowska', email: 'katarzyna.chrapkowska@sp12gdynia.edu.pl', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Karolina', last_name: 'Cybulska', email: 'karolina.cybulska@sp12gdynia.edu.pl', subjects: ['świetlica'] },
  { first_name: 'Katarzyna', last_name: 'Czekaj', email: 'katarzyna.czekaj@sp12gdynia.edu.pl', subjects: ['religia'] },
  { first_name: 'Natalia', last_name: 'Dadacz', email: 'natalia.dadacz@sp12gdynia.edu.pl', subjects: ['świetlica'] },
  { first_name: 'Anna', last_name: 'Dęby', email: 'anna.deby@sp12gdynia.edu.pl', subjects: %w[plastyka technika] },
  { first_name: 'Dorota', last_name: 'Furgalska', email: 'dorota.furgalska@sp12gdynia.edu.pl', subjects: ['pedagog'] },
  { first_name: 'Joanna', last_name: 'Gibaszek', email: 'joanna.gibaszek@sp12gdynia.edu.pl', subjects: ['wychowanie fizyczne'] },
  { first_name: 'Iwona', last_name: 'Głowacka', email: 'iwona.glowacka@sp12gdynia.edu.pl', subjects: ['świetlica'] },
  { first_name: 'Magdalena', last_name: 'Gołyszny', email: 'magdalena.golyszny@sp12gdynia.edu.pl', subjects: ['język polski'] },
  { first_name: 'Joanna', last_name: 'Grabowska', email: 'joanna.grabowska@sp12gdynia.edu.pl', subjects: ['świetlica'] },
  { first_name: 'Anna', last_name: 'Guzelak-Bronowicka', email: 'anna.guzelak@sp12gdynia.edu.pl', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Anna', last_name: 'Jabłońska', email: 'anna.jablonska@sp12gdynia.edu.pl', subjects: %w[muzyka technika] },
  { first_name: 'Beata', last_name: 'Janczak', email: 'beata.janczak@sp12gdynia.edu.pl', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Marta', last_name: 'Jankowska-Frączyk', email: 'marta.fraczyk@sp12gdynia.edu.pl', subjects: ['język polski'] },
  { first_name: 'Agnieszka', last_name: 'Jaroszuk', email: 'agnieszka.jaroszuk@sp12gdynia.edu.pl', subjects: ['język angielski'] },
  { first_name: 'Monika', last_name: 'Jarząb', email: 'monika.jarzab@sp12gdynia.edu.pl', subjects: ['wychowanie fizyczne'] },
  { first_name: 'Katarzyna', last_name: 'Junak', email: 'katarzyna.junak@sp12gdynia.edu.pl', subjects: ['logopeda'] },
  { first_name: 'Rafał', last_name: 'Kaczyński', email: 'rafal.kaczynski@sp12gdynia.edu.pl', subjects: ['wychowanie fizyczne'] },
  { first_name: 'Magdalena', last_name: 'Kandzora', email: 'magdalena.kandzora@sp12gdynia.edu.pl', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Anetta', last_name: 'Kisielewska', email: 'anetta.kisielewska@sp12gdynia.edu.pl', subjects: ['język polski'] },
  { first_name: 'Aleksandra', last_name: 'Kłopocka', email: 'aleksandra.klopocka@sp12gdynia.edu.pl', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Sandra', last_name: 'Knapińska', email: 'sandra.knapinska@sp12gdynia.edu.pl', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Izabela', last_name: 'Kudelska', email: 'izabela.kudelska@sp12gdynia.edu.pl', subjects: ['terapia pedagogiczna'] },
  { first_name: 'Ewa', last_name: 'Kuszewska', email: 'ewa.kuszewska@sp12gdynia.edu.pl', subjects: ['język polski'] },
  { first_name: 'Iga', last_name: 'Kwiatkowska', email: 'iga.kwiatkowska@sp12gdynia.edu.pl', subjects: ['historia', 'doradztwo zawodowe'] },
  { first_name: 'Renata', last_name: 'Loska', email: 'renata.loska@sp12gdynia.edu.pl', subjects: ['matematyka'] },
  { first_name: 'Ewa', last_name: 'Mielczarek', email: 'ewa.mielczarek@sp12gdynia.edu.pl', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Katarzyna', last_name: 'Milewska-Pijet', email: 'katarzyna.pijet@sp12gdynia.edu.pl', subjects: ['świetlica'] },
  { first_name: 'Małgorzata', last_name: 'Mościcka', email: 'malgorzata.moscicka@sp12gdynia.edu.pl', subjects: %w[fizyka matematyka] },
  { first_name: 'Joanna', last_name: 'Murawska', email: 'joanna.murawska@sp12gdynia.edu.pl', subjects: ['język angielski', 'geografia'] },
  { first_name: 'Natalia', last_name: 'Oniszczuk', email: 'natalia.oniszczuk@sp12gdynia.edu.pl', subjects: ['świetlica'] },
  { first_name: 'Krzysztof', last_name: 'Perkowski', email: 'krzysztof.perkowski@sp12gdynia.edu.pl', subjects: ['wychowanie fizyczne', 'edukacja dla bezpieczeństwa'] },
  { first_name: 'Grażyna', last_name: 'Pliszka', email: 'grazyna.pliszka@sp12gdynia.edu.pl', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Katarzyna', last_name: 'Połchowska', email: 'katarzyna.polchowska@sp12gdynia.edu.pl', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Marta', last_name: 'Richert', email: 'marta.richert@sp12gdynia.edu.pl', subjects: ['świetlica'] },
  { first_name: 'Joanna', last_name: 'Rodziewicz', email: 'joanna.rodziewicz@sp12gdynia.edu.pl', subjects: %w[matematyka chemia] },
  { first_name: 'Ewa', last_name: 'Rybak', email: 'ewa.rybak@sp12gdynia.edu.pl', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Agnieszka', last_name: 'Skulina', email: 'agnieszka.skulina@sp12gdynia.edu.pl', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Kasjana', last_name: 'Skulina', email: 'kasjana.skulina@sp12gdynia.edu.pl', subjects: ['język angielski'] },
  { first_name: 'Adam', last_name: 'Słowi', email: 'adam.slowi@sp12gdynia.edu.pl', subjects: ['wychowanie fizyczne'] },
  { first_name: 'Małgorzata', last_name: 'Sobczak-Korda', email: 'malgorzata.korda@sp12gdynia.edu.pl', subjects: ['język polski', 'biblioteka'] },
  { first_name: 'Grażyna', last_name: 'Sobiech', email: 'grazyna.sobiech@sp12gdynia.edu.pl', subjects: ['matematyka'] },
  { first_name: 'Małgorzata', last_name: 'Sowa', email: 'malgorzata.sowa@sp12gdynia.edu.pl', subjects: ['matematyka'] },
  { first_name: 'Marzenna', last_name: 'Stecka', email: 'marzena.stecka@sp12gdynia.edu.pl', subjects: %w[biologia przyroda] },
  { first_name: 'Justyna', last_name: 'Stefańska', email: 'justyna.stefanska@sp12gdynia.edu.pl', subjects: ['edukacja zdrowotna', 'wychowanie fizyczne'] },
  { first_name: 'Danuta', last_name: 'Styk', email: 'danuta.styk@sp12gdynia.edu.pl', subjects: ['matematyka'] },
  { first_name: 'Marta', last_name: 'Suligowska', email: 'marta.suligowska@sp12gdynia.edu.pl', subjects: ['chemia'] },
  { first_name: 'Hanna', last_name: 'Synak', email: 'hanna.synak@sp12gdynia.edu.pl', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Justyna', last_name: 'Szczurek', email: 'justyna.szczurek@sp12gdynia.edu.pl', subjects: ['język polski'] },
  { first_name: 'Anna', last_name: 'Szermelek', email: 'anna.szermelek@sp12gdynia.edu.pl', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Marta', last_name: 'Szermelek', email: 'marta.szermelek@sp12gdynia.edu.pl', subjects: ['psycholog'] },
  { first_name: 'Magdalena', last_name: 'Thiel-Sawczuk', email: 'magdalena.sawczuk@sp12gdynia.edu.pl', subjects: ['język niemiecki', 'biblioteka'] },
  { first_name: 'Kacper', last_name: 'Walkusch', email: 'kacper.walkusch@sp12gdynia.edu.pl', subjects: ['religia'] },
  { first_name: 'Anna', last_name: 'Wicek', email: 'anna.wicek@sp12gdynia.edu.pl', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Marek', last_name: 'Wirkus', email: 'marek.wirkus@sp12gdynia.edu.pl', subjects: ['religia'] },
  { first_name: 'Justyna', last_name: 'Wrześniowska', email: 'justyna.wrzesniowska@sp12gdynia.edu.pl', subjects: ['język angielski'] },
  { first_name: 'Dorota', last_name: 'Wypych', email: 'dorota.wypych@sp12gdynia.edu.pl', subjects: ['świetlica'] },
  { first_name: 'Marzena', last_name: 'Zawadzka', email: 'marzena.zawadzka@sp12gdynia.edu.pl', subjects: ['świetlica'] },
  { first_name: 'Paulina', last_name: 'Zielińska', email: 'paulina.nowak@sp12gdynia.edu.pl', subjects: ['nauczyciel wspomagający'] },
  { first_name: 'Olga', last_name: 'Ziemba', email: 'olga.ziemba@sp12gdynia.edu.pl', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Magdalena', last_name: 'Zmorzyńska', email: 'magdalena.zmorzynska@sp12gdynia.edu.pl', subjects: ['historia'] },
  { first_name: 'Krystyna', last_name: 'Żuchowska', email: 'krystyna.zuchowska@sp12gdynia.edu.pl', subjects: ['informatyka'] }
]

# Create teachers
teachers_data.each do |teacher_data|
  user = User.create!(
    email: teacher_data[:email],
    password: pwd,
    password_confirmation: pwd,
    first_name: teacher_data[:first_name],
    last_name: teacher_data[:last_name],
    locale: 'pl',
    school: school,
    confirmed_at: Time.current,
    phone: "+48#{rand(500_000_000..999_999_999)}",
    metadata: {
      subjects: teacher_data[:subjects] || []
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

log("Created #{teachers_data.length} staff members for SP12")
