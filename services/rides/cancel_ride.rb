# frozen_string_literal: true

# Business operation: requested|accepted -> cancelled.
# Owner-rider (ride.rider.user_id) or assigned owner-driver may cancel.
# Returns [:ok, ride] or [:error, :forbidden|:not_found|:invalid, details].

module Rides
  module CancelRide
    def self.call(id:, current_user:)
      ride = RideRepository.find(id)
      return [:error, :not_found, { ride: 'not found' }] if ride.nil?
      unless %w[requested accepted].include?(ride.status)
        return [:error, :invalid, { status: 'only requested or accepted rides can be cancelled' }]
      end

      rider = RiderRepository.find(ride.rider_id)
      driver = ride.driver_id.nil? ? nil : DriverRepository.find(ride.driver_id)

      allowed =
        if current_user.role == 'rider'
          !rider.nil? && rider.user_id == current_user.id
        elsif current_user.role == 'driver'
          !driver.nil? && driver.user_id == current_user.id
        else
          false
        end
      return [:error, :forbidden, { ride: 'not owned by current user' }] unless allowed

      updated = RideRepository.update(ride.id, status: 'cancelled')
      [:ok, updated]
    rescue Sequel::ValidationFailed => e
      [:error, :invalid, { base: e.message }]
    end
  end
end
