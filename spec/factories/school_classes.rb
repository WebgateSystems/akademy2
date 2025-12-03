FactoryBot.define do
  factory :school_class do
    school
    name { "#{rand(1..8)}#{('A'..'D').to_a.sample}" }
    year { '2024/2025' }
    qr_token { SecureRandom.uuid }
    metadata { {} }
  end
end
