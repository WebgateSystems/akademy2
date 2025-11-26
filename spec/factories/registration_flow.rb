FactoryBot.define do
  factory :registration_flow do
    id          { SecureRandom.uuid }
    step        { 'profile' }
    phone_code  { nil }
    phone_verified { false }
    pin_temp    { nil }
    expires_at  { 30.minutes.from_now }
    data        { {} }

    trait :verify_phone_step do
      step { 'verify_phone' }
      data do
        {
          'profile' => {
            'first_name' => 'John',
            'last_name' => 'Doe',
            'email' => 'john@example.com',
            'birthdate' => '01.01.2000',
            'phone' => '+48111111111'
          }
        }
      end
    end

    trait :phone_verified do
      phone_verified { true }
      phone_code { '0000' }
      data do
        {
          'phone' => { 'number' => '+48111111111', 'verified' => true }
        }
      end
    end

    trait :pin_set do
      pin_temp { '1234' }
      data do
        {
          'pin_temp' => { 'pin' => '1234' }
        }
      end
    end

    trait :confirmed_pin do
      step { 'finish' }
      data do
        {
          'pin' => { 'pin' => '1234' }
        }
      end
    end
  end
end
