# frozen_string_literal: true

# Hand-written input validation for payments (no DB, no HTTP).
# Returns { ok: bool, errors: hash }. Controllers map errors to 422.
# Transition legality (pending -> approved/declined) lives in
# services/payments/*. Amount is server-set from ride.price.

module PaymentValidator
  ALLOWED_CREATE = %w[ride_id idempotency_key].freeze
  WEBHOOK_STATUSES = %w[approved declined].freeze
  MAX_KEY = 100

  def self.validate_create(attrs)
    errors = {}
    unknown = attrs.keys.map(&:to_s) - ALLOWED_CREATE
    errors[:base] = "unknown attributes: #{unknown.join(', ')}" unless unknown.empty?

    errors[:ride_id] = 'is required' if blank?(attrs[:ride_id] || attrs['ride_id'])

    key = attrs[:idempotency_key] || attrs['idempotency_key']
    errors[:idempotency_key] = "is too long (maximum #{MAX_KEY} characters)" if !blank?(key) && key.to_s.length > MAX_KEY

    { ok: errors.empty?, errors: errors }
  end

  def self.validate_webhook(attrs)
    errors = {}
    tx = attrs[:transaction_id] || attrs['transaction_id'] ||
         attrs[:wompi_transaction_id] || attrs['wompi_transaction_id']
    st = attrs[:status] || attrs['status']

    errors[:transaction_id] = 'is required' if blank?(tx)
    if blank?(st)
      errors[:status] = 'is required'
    elsif !WEBHOOK_STATUSES.include?(st.to_s)
      errors[:status] = "must be one of: #{WEBHOOK_STATUSES.join(', ')}"
    end

    { ok: errors.empty?, errors: errors }
  end

  def self.blank?(value)
    value.nil? || value.to_s.strip.empty?
  end
end
