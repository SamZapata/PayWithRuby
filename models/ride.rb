# frozen_string_literal: true

# Domain model for rides. Table mapping + associations only.
# Input validation lives in validators/ride_validator.rb.
# Business rules (pricing, transitions) live in services/rides/.

class Ride < Sequel::Model(:rides)
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true

  STATUSES = %w[requested accepted completed cancelled].freeze

  many_to_one :rider
  many_to_one :driver

  def validate
    super
    validates_presence %i[rider_id origin destination price status]
    validates_includes STATUSES, :status, message: 'must be a valid status' unless status.nil?
    errors.add(:price, 'must be greater than or equal to 0') if !price.nil? && price < 0
  end
end
