module Api
  module Register
    class ProfileForm < BaseDryForm
      class Contract < Dry::Validation::Contract
        params do
          required(:first_name).filled(:string)
          required(:last_name).filled(:string)
          required(:email).filled(:string)
          required(:birthdate).filled(:string)
          required(:phone).filled(:string)
        end

        rule(:email) do
          normalized = value.to_s.strip.downcase

          unless URI::MailTo::EMAIL_REGEXP.match?(normalized)
            key.failure('has invalid format')
            next
          end

          key.failure('is already taken') if User.where('LOWER(email) = ?', normalized).exists?
        end

        rule(:birthdate) do
          key.failure('must be in DD.MM.YYYY format') unless value.match?(/\A\d{2}\.\d{2}\.\d{4}\z/)
        end

        rule(:phone) do
          key.failure('has invalid format') unless value.match?(/\A\+?\d{7,15}\z/)
        end
      end
    end
  end
end
