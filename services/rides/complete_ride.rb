# frozen_string_literal: true

# Business operation: accepted -> completed. Only the assigned owned driver.
# Returns [:ok, ride] or [:error, :forbidden|:not_found|:invalid, details].

module Rides
  module CompleteRide
    def self.call(id:, current_user:)
      return [:error, :forbidden, { role: 'only drivers can complete rides' }] unless current_user.role == 'driver'

      ride = RideRepository.find(id)
      return [:error, :not_found, { ride: 'not found' }] if ride.nil?
      return [:error, :invalid, { status: 'only accepted rides can be completed' }] unless ride.status == 'accepted'
      return [:error, :forbidden, { ride: 'not assigned to current user' }] if ride.driver_id.nil?

      driver = DriverRepository.find(ride.driver_id)
      return [:error, :forbidden, { ride: 'not assigned to current user' }] if driver.nil? || driver.user_id != current_user.id

      updated = RideRepository.update(ride.id, status: 'completed')
      [:ok, updated]
    rescue Sequel::ValidationFailed => e
      [:error, :invalid, { base: e.message }]
    end
  end
end
