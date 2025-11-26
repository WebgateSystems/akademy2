FactoryBot.define do
  factory :school do
    name { "#{FFaker::Education.school_name} w #{FFaker::AddressPL.city}" }
    city { FFaker::AddressPL.city }
    country { 'PL' }
    slug { name.parameterize }
    logo { nil }
  end
end
