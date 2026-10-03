# frozen_string_literal: true

# HTTP coordination for riders. Owns status codes.
# Flow: Validator -> Repository -> Serializer. No SQL, no business rules.

class RidersController
  def self.index(status: nil)
    [200, { data: RiderSerializer.list_to_h(RiderRepository.all(status: status)) }]
  end

  def self.show(id)
    rider = RiderRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Rider not found' } }] if rider.nil?

    [200, { data: RiderSerializer.to_h(rider) }]
  end

  def self.create(attrs)
    check = RiderValidator.validate_create(attrs)
    return [422, { error: { code: 'validation_error', message: 'Invalid rider', details: check[:errors] } }] unless check[:ok]

    begin
      rider = RiderRepository.create(attrs)
    rescue Sequel::UniqueConstraintViolation
      return [422, { error: { code: 'validation_error', message: 'Email already taken', details: { email: 'already taken' } } }]
    rescue Sequel::ValidationFailed => e
      return [422, { error: { code: 'validation_error', message: 'Invalid rider', details: { base: e.message } } }]
    end

    [201, { data: RiderSerializer.to_h(rider) }]
  end

  def self.update(id, attrs)
    rider = RiderRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Rider not found' } }] if rider.nil?

    check = RiderValidator.validate_update(attrs)
    return [422, { error: { code: 'validation_error', message: 'Invalid rider', details: check[:errors] } }] unless check[:ok]

    begin
      updated = RiderRepository.update(id, attrs)
    rescue Sequel::UniqueConstraintViolation
      return [422, { error: { code: 'validation_error', message: 'Email already taken', details: { email: 'already taken' } } }]
    rescue Sequel::ValidationFailed => e
      return [422, { error: { code: 'validation_error', message: 'Invalid rider', details: { base: e.message } } }]
    end

    [200, { data: RiderSerializer.to_h(updated) }]
  end

  # Soft delete: flips status to inactive, keeps the record for history.
  def self.destroy(id)
    rider = RiderRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Rider not found' } }] if rider.nil?

    deactivated = RiderRepository.deactivate(id)

    [200, { data: RiderSerializer.to_h(deactivated) }]
  end
end
