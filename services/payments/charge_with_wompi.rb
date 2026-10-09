# frozen_string_literal: true

# Business operation: charge a completed ride once (idempotent).
# Ownership via user_id FK: ride must belong to current_user's rider profile.
# Amount is server-set from ride.price; client amount is never trusted.
# Returns [:ok, payment, :created|:replayed] or
# [:error, :forbidden|:not_found|:invalid, details].

module Payments
  module ChargeWithWompi
    def self.call(ride_id:, current_user:, idempotency_key: nil)
      return [:error, :forbidden, { role: 'only riders can pay for rides' }] unless current_user.role == 'rider'

      profile = RiderRepository.find_by_user(current_user.id)
      return [:error, :forbidden, { user: 'no rider profile for this user' }] if profile.nil?

      ride = RideRepository.find(ride_id)
      return [:error, :not_found, { ride: 'not found' }] if ride.nil?
      return [:error, :forbidden, { ride: 'does not belong to current user' }] unless ride.rider_id.to_s == profile.id.to_s
      return [:error, :invalid, { status: 'only completed rides can be charged' }] unless ride.status == 'completed'

      existing = PaymentRepository.find_by_ride(ride.id)
      return [:ok, existing, :replayed] unless existing.nil?

      key = idempotency_key.to_s.strip.empty? ? "pay-ride-#{ride.id}" : idempotency_key.to_s.strip
      by_key = PaymentRepository.find_by_idempotency_key(key)
      return [:ok, by_key, :replayed] unless by_key.nil?

      result = WompiClient.charge(amount: ride.price, ride_id: ride.id, idempotency_key: key)
      payment = PaymentRepository.create(
        ride_id: ride.id,
        amount: ride.price,
        status: 'pending',
        wompi_transaction_id: result[:transaction_id],
        idempotency_key: key
      )
      [:ok, payment, :created]
    rescue Sequel::UniqueConstraintViolation
      # Concurrent retry race: unique on ride_id / key won, return existing.
      existing = PaymentRepository.find_by_ride(ride_id) ||
                 PaymentRepository.find_by_idempotency_key(idempotency_key.to_s)
      return [:ok, existing, :replayed] unless existing.nil?

      [:error, :invalid, { base: 'payment already exists' }]
    rescue Sequel::ValidationFailed => e
      [:error, :invalid, { base: e.message }]
    end
  end
end
