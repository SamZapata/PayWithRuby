# frozen_string_literal: true

# HTTP coordination for rides. Owns status codes.
# Flow: Validator -> Service -> Serializer. No SQL, no business rules.
# Writes require auth (routes enforce); ownership enforced in services
# via user_id FK match. Maps :forbidden -> 403, :not_found -> 404.

class RidesController
  def self.index(status: nil, rider_id: nil, driver_id: nil)
    check = RideValidator.validate_list(status: status)
    return [422, { error: { code: 'validation_error', message: 'Invalid filter', details: check[:errors] } }] unless check[:ok]

    [200, { data: RideSerializer.list_to_h(RideRepository.all(status: status, rider_id: rider_id, driver_id: driver_id)) }]
  end

  def self.show(id)
    ride = RideRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Ride not found' } }] if ride.nil?

    [200, { data: RideSerializer.to_h(ride) }]
  end

  def self.create(attrs, current_user)
    check = RideValidator.validate_create(attrs)
    return [422, { error: { code: 'validation_error', message: 'Invalid ride', details: check[:errors] } }] unless check[:ok]

    outcome, payload, details = Rides::CreateRide.call(
      rider_id: attrs[:rider_id] || attrs['rider_id'],
      origin: attrs[:origin] || attrs['origin'],
      destination: attrs[:destination] || attrs['destination'],
      current_user: current_user
    )
    return render_service_error(payload, details) unless outcome == :ok

    [201, { data: RideSerializer.to_h(payload) }]
  end

  def self.accept(id, attrs, current_user)
    check = RideValidator.validate_accept(attrs)
    return [422, { error: { code: 'validation_error', message: 'Invalid ride', details: check[:errors] } }] unless check[:ok]

    outcome, payload, details = Rides::AcceptRide.call(
      id: id, driver_id: attrs[:driver_id] || attrs['driver_id'], current_user: current_user
    )
    return render_service_error(payload, details) unless outcome == :ok

    [200, { data: RideSerializer.to_h(payload) }]
  end

  def self.complete(id, current_user)
    outcome, payload, details = Rides::CompleteRide.call(id: id, current_user: current_user)
    return render_service_error(payload, details) unless outcome == :ok

    [200, { data: RideSerializer.to_h(payload) }]
  end

  def self.cancel(id, current_user)
    outcome, payload, details = Rides::CancelRide.call(id: id, current_user: current_user)
    return render_service_error(payload, details) unless outcome == :ok

    [200, { data: RideSerializer.to_h(payload) }]
  end

  def self.render_service_error(kind, details)
    case kind
    when :forbidden
      [403, { error: { code: 'forbidden', message: 'Forbidden', details: details } }]
    when :not_found
      [404, { error: { code: 'not_found', message: 'Ride not found' } }]
    else
      [422, { error: { code: 'validation_error', message: 'Invalid ride', details: details } }]
    end
  end
end
