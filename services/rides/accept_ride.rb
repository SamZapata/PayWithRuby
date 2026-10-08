# frozen_string_literal: true

# Business operation: requested -> accepted, assigning the owned driver.
# Returns [:ok, ride] or [:error, :forbidden|:not_found|:invalid, details].

module Rides
  module AcceptRide
    def self.call(id:, driver_id:, current_user:)
      return [:error, :forbidden, { role: 'only drivers can accept rides' }] unless current_user.role == 'driver'

      profile = DriverRepository.find_by_user(current_user.id)
      return [:error, :forbidden, { user: 'no driver profile for this user' }] if profile.nil?
      return [:error, :forbidden, { driver_id: 'does not belong to current user' }] unless profile.id.to_s == driver_id.to_s
      return [:error, :invalid, { driver: 'is inactive' }] unless profile.status == 'active'

      ride = RideRepository.find(id)
      return [:error, :not_found, { ride: 'not found' }] if ride.nil?
      return [:error, :invalid, { status: 'only requested rides can be accepted' }] unless ride.status == 'requested'

      updated = RideRepository.update(ride.id, driver_id: profile.id, status: 'accepted')
      [:ok, updated]
    rescue Sequel::ValidationFailed => e
      [:error, :invalid, { base: e.message }]
    end
  end
end
