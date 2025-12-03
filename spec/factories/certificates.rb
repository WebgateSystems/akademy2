FactoryBot.define do
  factory :certificate do
    association :quiz_result

    certificate_number { SecureRandom.uuid }
    issued_at { Time.current }

    after(:build) do |certificate|
      file = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/test.pdf'),
        'application/pdf'
      )

      certificate.pdf = file
    end
  end
end
