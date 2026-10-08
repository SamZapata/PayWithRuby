# frozen_string_literal: true

# HTTP coordination for riders. Owns status codes.
# Flow: Validator -> Repository -> Serializer. No SQL, no business rules.
# Ownership via user_id FK: only role=rider users, one profile per user,
# updates/deletes only on owned records. user_id never comes from client.

class RidersController
  def self.index(status: nil)
    [200, { data: RiderSerializer.list_to_h(RiderRepository.all(status: status)) }]
  end

  def self.show(id)
    rider = RiderRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Rider not found' } }] if rider.nil?

    [200, { data: RiderSerializer.to_h(rider) }]
  end

  def self.create(attrs, current_user)
    return forbidden('only riders can create rider profiles') unless current_user.role == 'rider'
    return [422, { error: { code: 'validation_error', message: 'User already has a rider profile', details: { user: 'already has profile' } } }] unless RiderRepository.find_by_user(current_user.id).nil?

    safe = attrs.reject { |k, _| k.to_s == 'user_id' }
    check = RiderValidator.validate_create(safe)
    return [422, { error: { code: 'validation_error', message: 'Invalid rider', details: check[:errors] } }] unless check[:ok]

    begin
      rider = RiderRepository.create(safe.merge('user_id' => current_user.id))
    rescue Sequel::UniqueConstraintViolation
      return [422, { error: { code: 'validation_error', message: 'Email already taken', details: { email: 'already taken' } } }]
    rescue Sequel::ValidationFailed => e
      return [422, { error: { code: 'validation_error', message: 'Invalid rider', details: { base: e.message } } }]
    end

    [201, { data: RiderSerializer.to_h(rider) }]
  end

  def self.update(id, attrs, current_user)
    rider = RiderRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Rider not found' } }] if rider.nil?
    return forbidden('not owned by current user') unless rider.user_id == current_user.id

    safe = attrs.reject { |k, _| k.to_s == 'user_id' }
    check = RiderValidator.validate_update(safe)
    return [422, { error: { code: 'validation_error', message: 'Invalid rider', details: check[:errors] } }] unless check[:ok]

    begin
      updated = RiderRepository.update(id, safe)
    rescue Sequel::UniqueConstraintViolation
      return [422, { error: { code: 'validation_error', message: 'Email already taken', details: { email: 'already taken' } } }]
    rescue Sequel::ValidationFailed => e
      return [422, { error: { code: 'validation_error', message: 'Invalid rider', details: { base: e.message } } }]
    end

    [200, { data: RiderSerializer.to_h(updated) }]
  end

  # Soft delete: flips status to inactive, keeps the record for history.
  def self.destroy(id, current_user)
    rider = RiderRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Rider not found' } }] if rider.nil?
    return forbidden('not owned by current user') unless rider.user_id == current_user.id

    deactivated = RiderRepository.deactivate(id)

    [200, { data: RiderSerializer.to_h(deactivated) }]
  end

  def self.forbidden(message)
    [403, { error: { code: 'forbidden', message: message } }]
  end
end
