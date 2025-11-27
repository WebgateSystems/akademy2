# frozen_string_literal: true

class SchoolManagementPolicy < ApplicationPolicy
  def access?
    return false unless user

    # Ensure roles are loaded to avoid N+1 queries
    user.roles.load if user.roles.loaded? == false

    user_roles = user.roles.pluck(:key)
    user_roles.include?('principal') || user_roles.include?('school_manager')
  end
end
