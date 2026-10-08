# frozen_string_literal: true

# Hand-written input validation for rides (no DB, no HTTP).
# Returns { ok: bool, errors: hash }. Controllers map errors to 422.
# Transition legality (requested -> accepted -> completed/cancelled)
# lives in services/rides/*. State filtering for list lives here.

module RideValidator
  ALLOWED_CREATE = %w[rider_id origin destination].freeze
  ALLOWED_ACCEPT = %w[driver_id].freeze
  STATUSES = %w[requested accepted completed cancelled].freeze
  MAX = { 'origin' => 255, 'destination' => 255, 'status' => 20 }.freeze

  def self.validate_create(attrs)
    errors = {}
    unknown = attrs.keys.map(&:to_s) - ALLOWED_CREATE
    errors[:base] = "unknown attributes: #{unknown.join(', ')}" unless unknown.empty?

    errors[:rider_id] = 'is required' if blank?(attrs[:rider_id] || attrs['rider_id'])
    errors[:origin] = 'is required' if blank?(attrs[:origin] || attrs['origin'])
    errors[:destination] = 'is required' if blank?(attrs[:destination] || attrs['destination'])

    check_lengths(attrs, errors, ALLOWED_CREATE)

    { ok: errors.empty?, errors: errors }
  end

  def self.validate_accept(attrs)
    errors = {}
    unknown = attrs.keys.map(&:to_s) - ALLOWED_ACCEPT
    errors[:base] = "unknown attributes: #{unknown.join(', ')}" unless unknown.empty?

    errors[:driver_id] = 'is required' if blank?(attrs[:driver_id] || attrs['driver_id'])

    { ok: errors.empty?, errors: errors }
  end

  def self.validate_list(filters)
    errors = {}
    status = filters[:status] || filters['status']
    unless blank?(status) || STATUSES.include?(status.to_s)
      errors[:status] = "must be one of: #{STATUSES.join(', ')}"
    end

    { ok: errors.empty?, errors: errors }
  end

  def self.check_lengths(attrs, errors, keys)
    keys.map(&:to_s).each do |key|
      next unless MAX.key?(key)

      value = attrs[key.to_sym] || attrs[key]
      next if blank?(value)
      next unless value.to_s.length > MAX[key]

      errors[key.to_sym] ||= "is too long (maximum #{MAX[key]} characters)"
    end
  end

  def self.blank?(value)
    value.nil? || value.to_s.strip.empty?
  end
end
