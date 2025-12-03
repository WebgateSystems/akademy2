# frozen_string_literal: true

class AdministrationSerializer < ApplicationSerializer
  attributes :id, :first_name, :last_name, :email, :school_id, :created_at, :updated_at

  attribute :name do |administration|
    [administration.first_name, administration.last_name].compact.join(' ').presence || administration.email
  end

  attribute :school_name do |administration|
    administration.school&.name
  end

  attribute :phone, &:display_phone

  attribute :birth_date do |administration|
    administration.metadata&.dig('birth_date')
  end

  attribute :roles do |administration, params|
    # Get school_id from params (passed from interactor) or from administration's user_roles
    school_id = params&.dig(:school_id)
    Rails.logger.debug "AdministrationSerializer#roles - Admin ID: #{administration.id}, Params school_id: #{school_id}"

    unless school_id
      # Fallback: get school_id from user_roles (already preloaded)
      admin_role = administration.user_roles.find { |ur| %w[principal school_manager teacher].include?(ur.role&.key) }
      school_id = admin_role&.school_id
      Rails.logger.debug "AdministrationSerializer#roles - Fallback school_id: #{school_id}"
    end

    return [] unless school_id

    # Filter user_roles by school_id and role key (already preloaded)
    # Include principal, school_manager, and teacher roles
    filtered_roles = administration.user_roles.select do |ur|
      ur.school_id == school_id && %w[principal school_manager teacher].include?(ur.role&.key)
    end
    roles = filtered_roles.map { |ur| ur.role.key }

    Rails.logger.debug "AdministrationSerializer#roles - Final roles for admin #{administration.id}: #{roles.inspect}"
    roles
  end

  attribute :locked_at, &:locked_at

  attribute :is_locked do |administration|
    administration.locked_at.present?
  end

  attribute :confirmed_at, &:confirmed_at

  attribute :is_confirmed do |administration|
    administration.confirmed_at.present?
  end
end
