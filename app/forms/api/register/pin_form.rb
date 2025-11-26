module Api
  module Register
    class PinForm < BaseDryForm
      class Contract < Dry::Validation::Contract
        params do
          required(:pin).filled(:string)
        end

        rule(:pin) do
          key.failure('must be 4 digits') unless value.match?(/\A\d{4}\z/)
        end
      end
    end
  end
end
