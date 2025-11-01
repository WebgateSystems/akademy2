class Subscription < ApplicationRecord
  belongs_to :school
  belongs_to :plan
end
