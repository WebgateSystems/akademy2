# frozen_string_literal: true

module Admin
  # rubocop:disable I18n/GetText/DecorateString
  class EventBlockRuleBuilder
    def initialize(event:, kind:, params:)
      @event = event
      @kind = kind.to_s
      @params = params
    end

    # Returns a Hash with either:
    # - { rule_type:, value:, note:, ...optional preview fields... }
    # - { error: "..." }
    # - nil (invalid kind)
    def call
      case kind
      when 'user' then build_user
      when 'ip' then build_ip
      when 'network' then build_network
      end
    end

    private

    attr_reader :event, :kind, :params

    def build_user
      return { error: 'Ten event nie ma user_id — nie można zablokować użytkownika.' } if event.user_id.blank?

      { rule_type: 'user', value: event.user_id, note: "Blocked user from Event##{event.id}" }
    end

    def build_ip
      ip = event_ip
      return { error: 'Ten event nie ma IP — nie można zablokować IP.' } if ip.blank?

      { rule_type: 'ip', value: ip, note: "Blocked from Event##{event.id}" }
    end

    def build_network
      ip = event_ip
      return { error: 'Ten event nie ma IP — nie można zablokować sieci.' } if ip.blank?

      override = params[:value].presence || params.dig(:event_block, :value)
      return build_network_from_override(override, ip) if override.present?

      resolution = resolve_network(ip)
      return { error: 'Nie udało się wyliczyć sieci z IP.' } if resolution.nil?

      resolution.merge(note: "Blocked network (#{resolution[:resolution]}) from Event##{event.id} ip=#{ip}")
    end

    def build_network_from_override(override, ip)
      return { error: 'Nieprawidłowy CIDR.' } unless valid_cidr?(override)
      return { error: 'CIDR nie obejmuje IP eventu.' } unless cidr_includes_ip?(override, ip)

      {
        rule_type: 'cidr',
        value: override,
        ip: ip,
        resolution: 'confirmed',
        note: "Blocked network (confirmed) from Event##{event.id} ip=#{ip}"
      }
    end

    def event_ip
      (event.data || {})['ip'].presence
    end

    def resolve_network(ip)
      cidrs = NetworkLookupService.new(ip).cidrs
      if cidrs.present?
        chosen = choose_most_specific_cidr(cidrs, ip) || cidrs.first
        return { rule_type: 'cidr', value: chosen, ip: ip, resolution: 'rdap' }
      end

      fallback = derive_fallback_cidr(ip)
      return nil unless fallback

      { rule_type: 'cidr', value: fallback, ip: ip, resolution: 'fallback' }
    end

    def choose_most_specific_cidr(cidrs, ip)
      addr = IPAddr.new(ip)
      matches = cidrs.filter_map do |c|
        net = IPAddr.new(c)
        next unless net.include?(addr)

        prefix = c.to_s.split('/').last.to_i
        { cidr: c, prefix: prefix }
      rescue IPAddr::InvalidAddressError
        nil
      end
      matches.max_by { |m| m[:prefix] }&.fetch(:cidr, nil)
    rescue IPAddr::InvalidAddressError
      nil
    end

    def derive_fallback_cidr(ip)
      addr = IPAddr.new(ip)
      if addr.ipv4?
        "#{IPAddr.new(addr.to_i & IPAddr.new('255.255.255.0').to_i, Socket::AF_INET)}/24"
      else
        mask = IPAddr.new('ffff:ffff:ffff:ffff::', Socket::AF_INET6)
        "#{IPAddr.new(addr.to_i & mask.to_i, Socket::AF_INET6)}/64"
      end
    rescue IPAddr::InvalidAddressError
      nil
    end

    def valid_cidr?(cidr)
      IPAddr.new(cidr)
      cidr.to_s.include?('/')
    rescue IPAddr::InvalidAddressError
      false
    end

    def cidr_includes_ip?(cidr, ip)
      IPAddr.new(cidr).include?(IPAddr.new(ip))
    rescue IPAddr::InvalidAddressError
      false
    end
  end
  # rubocop:enable I18n/GetText/DecorateString
end
