# frozen_string_literal: true

require 'ipaddr'

class RequestBlockRule < ApplicationRecord
  TYPES = %w[ip cidr user].freeze

  validates :rule_type, presence: true, inclusion: { in: TYPES }
  validates :value, presence: true
  validates :enabled, inclusion: { in: [true, false] }

  belongs_to :created_by, class_name: 'User', optional: true

  scope :active, -> { where(enabled: true) }

  def self.blocked?(ip: nil, user_id: nil)
    return false if ip.blank? && user_id.blank?

    user_blocked?(user_id) || ip_blocked?(ip)
  end

  def self.user_blocked?(user_id)
    return false if user_id.blank?

    user_id_str = user_id.to_s
    active.where(rule_type: 'user', value: user_id_str).exists? ||
      active.where(rule_type: 'user').where('BTRIM(value) = ?', user_id_str).exists?
  end

  def self.ip_blocked?(ip)
    return false if ip.blank?

    normalized_ip = ip.to_s.strip
    return true if active.where(rule_type: 'ip', value: normalized_ip).exists?

    # CIDR matching needs Ruby (value is stored as string, and inet is not used here).
    active.where(rule_type: 'cidr').select(:value).any? do |r|
      r.matches?(ip: normalized_ip, user_id: nil)
    end
  end

  def matches?(ip:, user_id: nil)
    case rule_type
    when 'ip'
      ip.present? && value.to_s.strip == ip.to_s.strip
    when 'cidr'
      return false if ip.blank?

      cidr_includes_ip?(cidr: value, ip: ip)
    when 'user'
      return false if user_id.blank?

      value.to_s.strip == user_id.to_s.strip
    else
      false
    end
  end

  private

  def cidr_includes_ip?(cidr:, ip:)
    IPAddr.new(cidr).include?(IPAddr.new(ip))
  rescue IPAddr::InvalidAddressError
    false
  end
end
