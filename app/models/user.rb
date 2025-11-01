class User < ApplicationRecord
  # JWT revocation via JTIMatcher (wymaga kolumny :jti)
  include Devise::JWT::RevocationStrategies::JTIMatcher

  belongs_to :school, optional: true
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :confirmable,
         :lockable,
         :timeoutable,
         :trackable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self
end
