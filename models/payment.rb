# frozen_string_literal: true

# Domain model for payments. Table mapping + associations only.
# Input validation lives in validators/payment_validator.rb.
# Business rules (charge, webhook confirm) live in services/payments/.

class Payment < Sequel::Model(:payments)
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true

  STATUSES = %w[pending approved declined].freeze

  many_to_one :ride

  def validate
    super
    validates_presence %i[ride_id amount status idempotency_key]
    validates_includes STATUSES, :status, message: 'must be a valid status' unless status.nil?
    errors.add(:amount, 'must be greater than or equal to 0') if !amount.nil? && amount < 0
  end
end
