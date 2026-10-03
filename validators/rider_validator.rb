# frozen_string_literal: true

# Hand-written input validation for riders (no DB, no HTTP).
# Returns { ok: bool, errors: hash }. Controllers map errors to 422.

module RiderValidator
  ALLOWED_CREATE = %w[name email phone status].freeze
  ALLOWED_UPDATE = %w[name email phone status].freeze
  STATUSES = %w[active inactive].freeze
  EMAIL_RE = /\A[^@\s]+@[^@\s]+\z/
  MAX = { 'name' => 100, 'email' => 255, 'phone' => 30, 'status' => 20 }.freeze

  def self.validate_create(attrs)
    errors = {}
    unknown = attrs.keys.map(&:to_s) - ALLOWED_CREATE
    errors[:base] = "unknown attributes: #{unknown.join(', ')}" unless unknown.empty?

    errors[:name] = 'is required' if blank?(attrs[:name] || attrs['name'])
    email = attrs[:email] || attrs['email']
    errors[:email] = 'is required' if blank?(email)
    errors[:email] = 'is not a valid email' if !blank?(email) && email !~ EMAIL_RE

    status = attrs[:status] || attrs['status']
    errors[:status] = "must be one of: #{STATUSES.join(', ')}" if !blank?(status) && !STATUSES.include?(status.to_s)

    check_lengths(attrs, errors, ALLOWED_CREATE)

    { ok: errors.empty?, errors: errors }
  end

  def self.validate_update(attrs)
    errors = {}
    str_keys = attrs.keys.map(&:to_s)
    unknown = str_keys - ALLOWED_UPDATE
    errors[:base] = "unknown attributes: #{unknown.join(', ')}" unless unknown.empty?
    errors[:base] = 'no attributes to update' if str_keys.empty?

    if attrs.key?(:name) || attrs.key?('name')
      errors[:name] = 'cannot be blank' if blank?(attrs[:name] || attrs['name'])
    end
    if attrs.key?(:email) || attrs.key?('email')
      email = attrs[:email] || attrs['email']
      errors[:email] = 'cannot be blank' if blank?(email)
      errors[:email] = 'is not a valid email' if !blank?(email) && email !~ EMAIL_RE
    end
    if attrs.key?(:status) || attrs.key?('status')
      status = attrs[:status] || attrs['status']
      errors[:status] = "must be one of: #{STATUSES.join(', ')}" if !blank?(status) && !STATUSES.include?(status.to_s)
    end

    check_lengths(attrs, errors, str_keys)

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
