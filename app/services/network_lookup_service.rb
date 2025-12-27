# frozen_string_literal: true

require 'net/http'
require 'json'
require 'ipaddr'

# Looks up the allocation network for a given IP address using RDAP.
# Similar outcome to whatismyipaddress.com style "netblock" detection.
#
# Notes:
# - Uses `https://rdap.org/ip/<ip>` which redirects to the proper RIR.
# - Returns one or more CIDRs covering the allocation range.
class NetworkLookupService
  RDAP_URL = 'https://rdap.org/ip/'

  def initialize(ip)
    @ip = ip.to_s.strip
  end

  def cidrs
    data = fetch_rdap
    return [] unless data.is_a?(Hash)

    from_cidr0 = parse_cidr0(data)
    return from_cidr0 if from_cidr0.any?

    from_range = parse_range(data)
    return from_range if from_range.any?

    []
  rescue StandardError
    []
  end

  private

  attr_reader :ip

  def fetch_rdap
    uri = URI.join(RDAP_URL, ip)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 3
    http.read_timeout = 4

    req = Net::HTTP::Get.new(uri)
    req['Accept'] = 'application/rdap+json, application/json'

    resp = http.request(req)
    return nil unless resp.is_a?(Net::HTTPSuccess)

    JSON.parse(resp.body)
  end

  def parse_cidr0(data)
    cidrs = []
    Array(data['cidr0_cidrs']).each do |entry|
      length = entry['length']
      v4prefix = entry['v4prefix']
      v6prefix = entry['v6prefix']
      next unless length

      if v4prefix
        cidrs << "#{v4prefix}/#{length}"
      elsif v6prefix
        cidrs << "#{v6prefix}/#{length}"
      end
    end
    cidrs.uniq
  end

  def parse_range(data)
    start_addr = data['startAddress'].to_s.strip
    end_addr = data['endAddress'].to_s.strip
    return [] if start_addr.blank? || end_addr.blank?

    range_to_cidrs(start_addr, end_addr)
  end

  # Convert an IP range [start, end] into minimal CIDR blocks.
  # Works for IPv4 and IPv6.
  def range_to_cidrs(start_ip, end_ip)
    start_addr = IPAddr.new(start_ip)
    end_addr = IPAddr.new(end_ip)
    return [] if start_addr.family != end_addr.family

    bits = start_addr.ipv4? ? 32 : 128
    family = start_addr.family
    start_int = start_addr.to_i
    end_int = end_addr.to_i
    return [] if end_int < start_int

    build_cidrs_for_range(start_int: start_int, end_int: end_int, family: family, bits: bits)
  rescue IPAddr::InvalidAddressError
    []
  end

  def build_cidrs_for_range(start_int:, end_int:, family:, bits:)
    out = []
    cur = start_int
    while cur <= end_int
      out << cidr_for_next_block(cur: cur, end_int: end_int, family: family, bits: bits)
      cur += out.last.fetch(:block_size)
      out[-1] = out.last.fetch(:cidr)
    end
    out
  end

  def cidr_for_next_block(cur:, end_int:, family:, bits:)
    max_align_size = max_aligned_block_size(cur, bits)
    remaining = end_int - cur + 1
    block_size = [max_align_size, highest_power_of_two_leq(remaining)].min
    prefix = bits - integer_log2(block_size)
    { cidr: "#{IPAddr.new(cur, family)}/#{prefix}", block_size: block_size }
  end

  def max_aligned_block_size(value, bits)
    return 2**bits if value.zero?

    2**trailing_zeros(value, bits)
  end

  def trailing_zeros(value, bits)
    tz = 0
    while tz < bits && (value & 1).zero?
      tz += 1
      value >>= 1
    end
    tz
  end

  def highest_power_of_two_leq(num)
    return 1 if num <= 1

    2**integer_log2(num)
  end

  def integer_log2(num)
    num.to_i.bit_length - 1
  end
end
