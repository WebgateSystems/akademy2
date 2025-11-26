# frozen_string_literal: true

return if User.joins(:roles).where(roles: { key: 'teacher' }, school: @school_a).exists?

log('Create Teachers for SP53...')

pwd = 'devpass!'
teacher_role = Role.find_by!(key: 'teacher')

# Teachers from https://sp53gdynia.pl/index.php/nauczyciele
teachers_data = [
  { first_name: 'Angelika', last_name: 'Badorek', subjects: ['matematyka'], class: '7na' },
  { first_name: 'Katarzyna', last_name: 'Bańcerek', class: '0a' },
  { first_name: 'Małgorzata', last_name: 'Bielska', subjects: ['pedagog specjalny', 'technika', 'plastyka'], class: '3nb' },
  { first_name: 'Magdalena', last_name: 'Czubak', subjects: ['matematyka'], class: '7b' },
  { first_name: 'Aneta', last_name: 'Ćwiklińska', subjects: ['język polski'], class: '4b, 5na' },
  { first_name: 'Anna', last_name: 'Danielowska', subjects: ['edukacja wczesnoszkolna'], class: '3a' },
  { first_name: 'Jolanta', last_name: 'Domagalska', subjects: ['matematyka'], class: '5b' },
  { first_name: 'Małgorzata', last_name: 'Dominiak', subjects: ['edukacja wczesnoszkolna'], class: '1na' },
  { first_name: 'Danuta', last_name: 'Durowska', subjects: ['edukacja wczesnoszkolna', 'historia', 'WOS'], class: '3b' },
  { first_name: 'Klaudia', last_name: 'Dzwonkowska-Elminowska', subjects: ['religia'] },
  { first_name: 'Paweł', last_name: 'Fryszka', subjects: ['etyka', 'edukacja zdrowotna'] },
  { first_name: 'Olimpia', last_name: 'Galińska', subjects: ['j. polski', 'logopedia'], class: '6b' },
  { first_name: 'Małgorzata', last_name: 'Gocel', class: '0a' },
  { first_name: 'Przemysław', last_name: 'Gora', subjects: ['informatyka'] },
  { first_name: 'Anna', last_name: 'Gosińska', subjects: ['j.polski'] },
  { first_name: 'Aleksandra', last_name: 'Grabowska-Stosik', subjects: ['edukacja wczesnoszkolna'] },
  { first_name: 'Anna', last_name: 'Gradowska', subjects: ['historia', 'WOS', 'wychowanie do życia w rodzinie'] },
  { first_name: 'Dominika', last_name: 'Gutowska', subjects: ['j. polski'] },
  { first_name: 'Alina', last_name: 'Haponenko', class: '8a' },
  { first_name: 'Katarzyna', last_name: 'Hupka', subjects: ['religia'] },
  { first_name: 'Hanna', last_name: 'Hyży', subjects: ['religia', 'edukacja zdrowotna'] },
  { first_name: 'Agata', last_name: 'Jarzembowska', subjects: ['język angielski'], class: '5a' },
  { first_name: 'Piotr', last_name: 'Juszczak' },
  { first_name: 'Anna', last_name: 'Kajetaniak', subjects: ['język angielski'], class: '7a' },
  { first_name: 'Katarzyna', last_name: 'Kapusta', subjects: ['doradztwo zawodowe'], class: '4na' },
  { first_name: 'Jolanta', last_name: 'Kasperek-Sut', subjects: ['chemia'] },
  { first_name: 'Marzena', last_name: 'Kitłowska-Kurpiel', subjects: ['język polski', 'logopedia'], class: '7nb' },
  { first_name: 'Kamila', last_name: 'Kołosowska' },
  { first_name: 'Daria', last_name: 'Koprowska', subjects: ['wychowanie przedszkolne'], class: '1A' },
  { first_name: 'Barbara', last_name: 'Kowalczuk', subjects: ['historia'] },
  { first_name: 'Mariusz', last_name: 'Kowalczyk', subjects: ['muzyka', 'informatyka', 'gimnastyka korekcyjna'], class: '6c' },
  { first_name: 'Paulina', last_name: 'Kunz', subjects: ['wychowanie fizyczne', 'matematyka'] },
  { first_name: 'Piotr', last_name: 'Madejski', subjects: ['wychowanie fizyczne', 'gimnastyka korekcyjna'], class: '8a' },
  { first_name: 'Patryk', last_name: 'Michna', subjects: ['wychowanie fizyczne', 'rewalidacja'], class: '8na' },
  { first_name: 'Anastazia', last_name: 'Młyńska' },
  { first_name: 'Lucyna', last_name: 'Murczak', subjects: ['pedagog specjalny', 'rewalidacja'], class: '5a' },
  { first_name: 'Magdalena', last_name: 'Natucka', subjects: ['j. angielski'], class: '3NA' },
  { first_name: 'Marta', last_name: 'Noińska', subjects: ['j. niemiecki'] },
  { first_name: 'Małgorzata', last_name: 'Onasch-Ptaszyńska', subjects: ['przyroda'] },
  { first_name: 'Karolina', last_name: 'Orlikowska-Pokrywka', subjects: ['biologia'] },
  { first_name: 'Anna', last_name: 'Pankau', subjects: ['zajęcia rewalidacyjne'], class: '4NA' },
  { first_name: 'Agnieszka', last_name: 'Petek', subjects: ['edukacja wczesnoszkolna', 'j. angielski'], class: '2b' },
  { first_name: 'Monika', last_name: 'Pietroczuk', subjects: ['język niemiecki'] },
  { first_name: 'Aleksandra', last_name: 'Podgórska', subjects: ['matematyka', 'fizyka', 'edukacja dla bezpieczeństwa'], class: '8C' },
  { first_name: 'Anna', last_name: 'Popiołek', subjects: ['j. polski dla obcokrajowców', 'biologia'] },
  { first_name: 'Magdalena', last_name: 'Powajbo-Gromadzka', subjects: ['j. angielski'], class: '5nb' },
  { first_name: 'Agnieszka', last_name: 'Reder', subjects: ['edukacja wczesnoszkolna', 'j. angielski'], class: '2N' },
  { first_name: 'Urszula', last_name: 'Roman', subjects: ['wychowanie przedszkolne'], class: '2a' },
  { first_name: 'Maja', last_name: 'Sacewicz', class: '6c' },
  { first_name: 'Zofia', last_name: 'Skrodziuk', subjects: ['biblioteka'] },
  { first_name: 'Karolina', last_name: 'Skrzypniak', class: '1nb' },
  { first_name: 'Wioletta', last_name: 'Somnicka', subjects: ['pedagog szkolny'] },
  { first_name: 'Aleksandra', last_name: 'Sosnowska', subjects: ['wychowanie fizyczne'], class: '7c' },
  { first_name: 'Katarzyna', last_name: 'Starostka', subjects: ['logopedia'] },
  { first_name: 'Grażyna', last_name: 'Stefaniak', subjects: ['j. polski'] },
  { first_name: 'Iwona', last_name: 'Sularz', class: '6b' },
  { first_name: 'Monika', last_name: 'Syrokwarz' },
  { first_name: 'Justyna', last_name: 'Szemplińska', class: '1b' },
  { first_name: 'Przemysław', last_name: 'Szlosek', subjects: ['geografia'] },
  { first_name: 'Hanna', last_name: 'Szumińska', subjects: ['wychowanie fizyczne', 'rewalidacja'], class: '8b' },
  { first_name: 'Katarzyna', last_name: 'Taranda', subjects: ['j. polski'] },
  { first_name: 'Karolina', last_name: 'Tomporowska', subjects: ['logopedia'] },
  { first_name: 'Agnieszka', last_name: 'Wierzbicka', subjects: ['psycholog'] },
  { first_name: 'Paweł', last_name: 'Wilmański', subjects: ['j. niemiecki'] },
  { first_name: 'Anna', last_name: 'Wojtek-Tarasiewicz', subjects: %w[plastyka technika] },
  { first_name: 'Natalia', last_name: 'Wołowicz' },
  { first_name: 'Aleksandra', last_name: 'Wysocka', subjects: ['logopedia'], class: '6a' },
  { first_name: 'Paweł', last_name: 'Zajączkowski', subjects: ['j.polski'] },
  { first_name: 'Magdalena', last_name: 'Zasadzińska', subjects: ['edukacja wczesnoszkolna', 'rewalidacja'], class: '1b' },
  { first_name: 'Edyta', last_name: 'Zegarlicka', subjects: ['wczesna edukacja'] },
  { first_name: 'Hanna', last_name: 'Zydorek', subjects: %w[przyroda biologia chemia], class: '6a' }
]

teachers_data.each_with_index do |teacher_data, index|
  email = "nauczyciel.sp53.#{index + 1}@akademy.local"
  user = User.create!(
    email: email,
    password: pwd,
    password_confirmation: pwd,
    first_name: teacher_data[:first_name],
    last_name: teacher_data[:last_name],
    locale: 'pl',
    school: @school_a,
    confirmed_at: Time.current,
    metadata: {
      subjects: teacher_data[:subjects] || [],
      class: teacher_data[:class] || nil
    }
  )
  UserRole.create!(user: user, role: teacher_role, school: @school_a)
end
