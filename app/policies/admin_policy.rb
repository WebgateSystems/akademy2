class AdminPolicy < ApplicationPolicy
  # def access?
  #   return false unless user
  #   user.roles.where(key: %w[admin manager]).exists?
  # end

  def access?
    user&.admin? # здесь определяет, может ли юзер в админку
  end
end
