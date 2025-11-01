class AdminPolicy < ApplicationPolicy
  def access?
    return false unless user
    user.roles.where(key: %w[admin manager]).exists?
  end
end


