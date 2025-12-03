# frozen_string_literal: true

# Check if teachers from this seed already exist (by checking if any teacher with teacher role
# has email from sp18.edu.gdynia.pl domain or generated email pattern)
return if User.joins(:roles)
              .where(roles: { key: 'teacher' })
              .where('email LIKE ? OR email LIKE ?', '%@sp18.edu.gdynia.pl', 'nauczyciel.sp18.%@akademy.local')
              .exists?

log('Create Teachers for SP18...')

pwd = 'devpass!'
teacher_role = Role.find_by!(key: 'teacher')

# Teachers from https://sp18.gdynia.pl/nauczyciele,57,pl
teachers_data = [
  { first_name: 'Sylwia', last_name: 'Chmarzyńska', email: 'schmarzynska@sp18.edu.gdynia.pl', subjects: %w[biblioteka czytelnia] },
  { first_name: 'Krzysztofia', last_name: 'Princ-Kruczek', email: 'kprinckruczek@sp18.edu.gdynia.pl', subjects: %w[biblioteka czytelnia] },
  { first_name: 'Ilona', last_name: 'Biłek-Landowska', email: 'i.bileklandowska@sp18.edu.gdynia.pl', subjects: ['biologia', 'edukacja zdrowotna', 'przyroda'] },
  { first_name: 'Aneta', last_name: 'Zocholl', email: 'zocholla@sp18.gdynia.pl', subjects: ['chemia'] },
  { first_name: 'Emilia', last_name: 'Kantecka', email: 'ekantecka@sp18.edu.gdynia.pl', subjects: ['chemia'] },
  { first_name: 'Karolina', last_name: 'Luty', email: 'kluty@sp18.edu.gdynia.pl', subjects: ['edukacja dla bezpieczeństwa', 'przyroda', 'wychowanie fizyczne'] },
  { first_name: 'Karina', last_name: 'Bogdaniuk-Sierant', email: 'ksierant@sp18.edu.gdynia.pl', subjects: ['edukacja zintegrowana'] },
  { first_name: 'Joanna', last_name: 'Iszczek', email: 'jiszczek@sp18.edu.gdynia.pl', subjects: ['edukacja zintegrowana'] },
  { first_name: 'Nicole', last_name: 'Gnap', email: 'ngnap@sp18.edu.gdynia.pl', subjects: ['edukacja zintegrowana'] },
  { first_name: 'Anna', last_name: 'Piasecka', email: 'apiasecka@sp18.edu.gdynia.pl', subjects: ['edukacja zintegrowana'] },
  { first_name: 'Anna', last_name: 'Ryta', email: 'aryta@sp18.edu.gdynia.pl', subjects: ['edukacja zintegrowana'] },
  { first_name: 'Monika', last_name: 'Chilicka', email: 'mchilicka@sp18.edu.gdynia.pl', subjects: ['edukacja zintegrowana'] },
  { first_name: 'Bożena', last_name: 'Żurawska', email: 'bzurawska@sp18.edu.gdynia.pl', subjects: ['edukacja zintegrowana'] },
  { first_name: 'Karina', last_name: 'Sankowska', email: 'ksankowska@sp18.edu.gdynia.pl', subjects: %w[fizyka matematyka] },
  { first_name: 'Maciej', last_name: 'Frankiewicz', email: 'mfrankiewicz@sp18.edu.gdynia.pl', subjects: ['geografia'] },
  { first_name: 'Dorota', last_name: 'Dudzicz', email: 'ddudzicz@sp18.edu.gdynia.pl', subjects: %w[historia wos] },
  { first_name: 'Justyna', last_name: 'Jellonnek', email: 'jjellonnek@sp18.edu.gdynia.pl', subjects: %w[historia wos] },
  { first_name: 'Elżbieta', last_name: 'Witkowska', email: 'ewitkowska@sp18.edu.gdynia.pl', subjects: ['informatyka'] },
  { first_name: 'Anna', last_name: 'Kozak', email: 'akozak@sp18.edu.gdynia.pl', subjects: ['j. polski'] },
  { first_name: 'Sylwia', last_name: 'Kwiatkowska', email: 'skwiatkowska@sp18.edu.gdynia.pl', subjects: ['j. polski'] },
  { first_name: 'Honorata', last_name: 'Łoś', email: 'hlos@sp18.edu.gdynia.pl', subjects: ['j. polski'] },
  { first_name: 'Dorota', last_name: 'Kaluga', email: 'dkaluga@sp18.edu.gdynia.pl', subjects: ['matematyka'] },
  { first_name: 'Beata', last_name: 'Łata', email: 'blata@sp18.edu.gdynia.pl', subjects: ['matematyka'] },
  { first_name: 'Beata', last_name: 'Siemińska', email: 'bsieminska@sp18.edu.gdynia.pl', subjects: ['matematyka'] },
  { first_name: 'Justyna', last_name: 'Krawczyk', email: 'jkrawczyk@sp18.edu.gdynia.pl', subjects: ['matematyka'] },
  { first_name: 'Ewa', last_name: 'Jabłonowska-Stojek', email: 'ejablonowskastojek@sp18.edu.gdynia.pl', subjects: ['matematyka'] },
  { first_name: 'Małgorzata', last_name: 'Portee', email: 'mportee@sp18.edu.gdynia.pl', subjects: %w[muzyka plastyka] },
  { first_name: 'Anna', last_name: 'Sieracka', email: 'asieracka@sp18.edu.gdynia.pl', subjects: ['technika'] },
  { first_name: 'Mariola', last_name: 'Gęsikiewicz', email: 'mgesikiewicz@sp18.edu.gdynia.pl', subjects: ['religia'] },
  { first_name: 'Adam', last_name: 'Hrubiszewski', email: 'ahrubiszewski@sp18.edu.gdynia.pl', subjects: ['religia'] },
  { first_name: 'Marta', last_name: 'Kędziora', email: 'kedzioram@sp18.gdynia.pl', subjects: ['kierownik świetlicy'] },
  { first_name: 'Aneta', last_name: 'Szymerowska', email: 'aszymerowska@sp18.edu.gdynia.pl', subjects: ['świetlica'] },
  { first_name: 'Walentyna', last_name: 'Traczyńska', email: 'traczynskaw@sp18.gdynia.pl', subjects: ['świetlica'] },
  { first_name: 'Marta', last_name: 'Ulanowska', email: 'mulanowska@sp18.edu.gdynia.pl', subjects: ['świetlica'] },
  { first_name: 'Agnieszka', last_name: 'Chabowska', email: 'achabowska@sp18.edu.gdynia.pl', subjects: ['świetlica'] },
  { first_name: 'Małgorzata', last_name: 'Staniszewska', email: nil, subjects: ['świetlica'] },
  { first_name: 'Monika', last_name: 'Gładykowska', email: 'mgladykowska@sp18.edu.gdynia.pl', subjects: ['świetlica'] },
  { first_name: 'Jacek', last_name: 'Kargol', email: 'jkargol@sp18.edu.gdynia.pl', subjects: ['wychowanie fizyczne'] },
  { first_name: 'Karolina', last_name: 'Wieczorek', email: 'kwieczorek@sp18.edu.gdynia.pl', subjects: ['wychowanie fizyczne'] },
  { first_name: 'Ireneusz', last_name: 'Zieliński', email: 'izielinski@sp18.edu.gdynia.pl', subjects: ['wychowanie fizyczne', 'edukacja dla bezpieczeństwa'] },
  { first_name: 'Anna', last_name: 'Olbromska', email: 'aolbromska@sp18.edu.gdynia.pl', subjects: ['nauczyciel wspomagający kształcenie'] },
  { first_name: 'Olga', last_name: 'Kwiatkowska', email: 'okwiatkowska@sp18.edu.gdynia.pl', subjects: ['nauczyciel wspomagający kształcenie'] },
  { first_name: 'Renata', last_name: 'Wolińska', email: 'rwolinska@sp18.edu.gdynia.pl', subjects: ['pedagog'] },
  { first_name: 'Karolina', last_name: 'Leśniak', email: 'klesniak@sp18.edu.gdynia.pl', subjects: ['psycholog'] }
]

teachers_data.each_with_index do |teacher_data, index|
  # Use provided email or generate one
  email = teacher_data[:email] || "nauczyciel.sp18.#{index + 1}@akademy.local"

  user = User.create!(
    email: email,
    password: pwd,
    password_confirmation: pwd,
    first_name: teacher_data[:first_name],
    last_name: teacher_data[:last_name],
    locale: 'pl',
    school: @school_b,
    confirmed_at: Time.current,
    phone: "+48#{rand(500_000_000..999_999_999)}",
    metadata: {
      subjects: teacher_data[:subjects] || []
    }
  )

  UserRole.create!(user: user, role: teacher_role, school: @school_b)
end
