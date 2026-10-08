# frozen_string_literal: true

# HTTP coordination for drivers. Owns status codes.
# Ownership via user_id FK: only role=driver users, one profile per user,
# updates/deletes only on owned records. user_id never comes from client.

class DriversController
  def self.index(status: nil)
    [200, { data: DriverSerializer.list_to_h(DriverRepository.all(status: status)) }]
  end

  def self.show(id)
    driver = DriverRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Driver not found' } }] if driver.nil?

    [200, { data: DriverSerializer.to_h(driver) }]
  end

  def self.create(attrs, current_user)
    return forbidden('only drivers can create driver profiles') unless current_user.role == 'driver'
    return [422, { error: { code: 'validation_error', message: 'User already has a driver profile', details: { user: 'already has profile' } } }] unless DriverRepository.find_by_user(current_user.id).nil?

    safe = attrs.reject { |k, _| k.to_s == 'user_id' }
    check = DriverValidator.validate_create(safe)
    return [422, { error: { code: 'validation_error', message: 'Invalid driver', details: check[:errors] } }] unless check[:ok]

    begin
      driver = DriverRepository.create(safe.merge('user_id' => current_user.id))
    rescue Sequel::UniqueConstraintViolation
      return [422, { error: { code: 'validation_error', message: 'Email or license plate already taken', details: { base: 'already taken' } } }]
    rescue Sequel::ValidationFailed => e
      return [422, { error: { code: 'validation_error', message: 'Invalid driver', details: { base: e.message } } }]
    end

    [201, { data: DriverSerializer.to_h(driver) }]
  end

  def self.update(id, attrs, current_user)
    driver = DriverRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Driver not found' } }] if driver.nil?
    return forbidden('not owned by current user') unless driver.user_id == current_user.id

    safe = attrs.reject { |k, _| k.to_s == 'user_id' }
    check = DriverValidator.validate_update(safe)
    return [422, { error: { code: 'validation_error', message: 'Invalid driver', details: check[:errors] } }] unless check[:ok]

    begin
      updated = DriverRepository.update(id, safe)
    rescue Sequel::UniqueConstraintViolation
      return [422, { error: { code: 'validation_error', message: 'Email or license plate already taken', details: { base: 'already taken' } } }]
    rescue Sequel::ValidationFailed => e
      return [422, { error: { code: 'validation_error', message: 'Invalid driver', details: { base: e.message } } }]
    end

    [200, { data: DriverSerializer.to_h(updated) }]
  end

  # Soft delete: flips status to inactive, keeps the record for history.
  def self.destroy(id, current_user)
    driver = DriverRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Driver not found' } }] if driver.nil?
    return forbidden('not owned by current user') unless driver.user_id == current_user.id

    deactivated = DriverRepository.deactivate(id)

    [200, { data: DriverSerializer.to_h(deactivated) }]
  end

  def self.forbidden(message)
    [403, { error: { code: 'forbidden', message: message } }]
  end
end
