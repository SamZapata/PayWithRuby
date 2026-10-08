# frozen_string_literal: true

# Business operation: create a ride in requested status.
# Ownership via user_id FK: rider_id must belong to current_user.
# Returns [:ok, ride] or [:error, :forbidden|:not_found|:invalid, details].

module Rides
  module CreateRide
    def self.call(rider_id:, origin:, destination:, current_user:)
      return [:error, :forbidden, { role: 'only riders can create rides' }] unless current_user.role == 'rider'

      profile = RiderRepository.find_by_user(current_user.id)
      return [:error, :forbidden, { user: 'no rider profile for this user' }] if profile.nil?
      return [:error, :forbidden, { rider_id: 'does not belong to current user' }] unless profile.id.to_s == rider_id.to_s
      return [:error, :invalid, { rider: 'is inactive' }] unless profile.status == 'active'

      price = PriceRide.call(origin, destination)
      ride = RideRepository.create(
        rider_id: profile.id, origin: origin, destination: destination,
        price: price, status: 'requested'
      )
      [:ok, ride]
    rescue Sequel::ValidationFailed => e
      [:error, :invalid, { base: e.message }]
    end
  end
end
