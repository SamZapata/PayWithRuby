# frozen_string_literal: true

# HTTP coordination for drivers. Owns status codes.

class DriversController
  def self.index(status: nil)
    [200, { data: DriverSerializer.list_to_h(DriverRepository.all(status: status)) }]
  end

  def self.show(id)
    driver = DriverRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Driver not found' } }] if driver.nil?

    [200, { data: DriverSerializer.to_h(driver) }]
  end

  def self.create(attrs)
    check = DriverValidator.validate_create(attrs)
    return [422, { error: { code: 'validation_error', message: 'Invalid driver', details: check[:errors] } }] unless check[:ok]

    begin
      driver = DriverRepository.create(attrs)
    rescue Sequel::UniqueConstraintViolation
      return [422, { error: { code: 'validation_error', message: 'Email or license plate already taken', details: { base: 'already taken' } } }]
    rescue Sequel::ValidationFailed => e
      return [422, { error: { code: 'validation_error', message: 'Invalid driver', details: { base: e.message } } }]
    end

    [201, { data: DriverSerializer.to_h(driver) }]
  end

  def self.update(id, attrs)
    driver = DriverRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Driver not found' } }] if driver.nil?

    check = DriverValidator.validate_update(attrs)
    return [422, { error: { code: 'validation_error', message: 'Invalid driver', details: check[:errors] } }] unless check[:ok]

    begin
      updated = DriverRepository.update(id, attrs)
    rescue Sequel::UniqueConstraintViolation
      return [422, { error: { code: 'validation_error', message: 'Email or license plate already taken', details: { base: 'already taken' } } }]
    rescue Sequel::ValidationFailed => e
      return [422, { error: { code: 'validation_error', message: 'Invalid driver', details: { base: e.message } } }]
    end

    [200, { data: DriverSerializer.to_h(updated) }]
  end

  # Soft delete: flips status to inactive, keeps the record for history.
  def self.destroy(id)
    driver = DriverRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Driver not found' } }] if driver.nil?

    deactivated = DriverRepository.deactivate(id)

    [200, { data: DriverSerializer.to_h(deactivated) }]
  end
end
