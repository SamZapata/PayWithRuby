# frozen_string_literal: true

# HTTP coordination for payments. Owns status codes.
# Flow: Validator -> Service -> Serializer. No SQL, no business rules.
# POST /payments requires rider-owner auth (routes enforce).
# POST /payments/webhook is public (Wompi calls it, no JWT).
# Maps :forbidden -> 403, :not_found -> 404, else 422.

class PaymentsController
  def self.create(attrs, current_user)
    check = PaymentValidator.validate_create(attrs)
    return [422, { error: { code: 'validation_error', message: 'Invalid payment', details: check[:errors] } }] unless check[:ok]

    outcome = Payments::ChargeWithWompi.call(
      ride_id: attrs[:ride_id] || attrs['ride_id'],
      idempotency_key: attrs[:idempotency_key] || attrs['idempotency_key'],
      current_user: current_user
    )
    return render_service_error(outcome[1], outcome[2]) unless outcome[0] == :ok

    _ok, payment, mode = outcome
    status = mode == :replayed ? 200 : 201
    [status, { data: PaymentSerializer.to_h(payment) }]
  end

  def self.show(id, current_user)
    payment = PaymentRepository.find(id)
    return [404, { error: { code: 'not_found', message: 'Payment not found' } }] if payment.nil?

    ride = RideRepository.find(payment.ride_id)
    return [403, { error: { code: 'forbidden', message: 'Forbidden', details: { payment: 'not owned by current user' } } }] unless owned?(ride, current_user)

    [200, { data: PaymentSerializer.to_h(payment) }]
  end

  def self.webhook(attrs)
    check = PaymentValidator.validate_webhook(attrs)
    return [422, { error: { code: 'validation_error', message: 'Invalid webhook', details: check[:errors] } }] unless check[:ok]

    tx = attrs[:transaction_id] || attrs['transaction_id'] ||
         attrs[:wompi_transaction_id] || attrs['wompi_transaction_id']
    st = attrs[:status] || attrs['status']

    outcome, payload, details = Payments::ConfirmPayment.call(transaction_id: tx.to_s, status: st.to_s)
    return render_service_error(payload, details) unless outcome == :ok

    [200, { data: PaymentSerializer.to_h(payload) }]
  end

  def self.owned?(ride, current_user)
    return false if ride.nil? || current_user.nil?

    if current_user.role == 'rider'
      profile = RiderRepository.find_by_user(current_user.id)
      !profile.nil? && ride.rider_id.to_s == profile.id.to_s
    elsif current_user.role == 'driver'
      profile = DriverRepository.find_by_user(current_user.id)
      !profile.nil? && !ride.driver_id.nil? && ride.driver_id.to_s == profile.id.to_s
    else
      false
    end
  end

  def self.render_service_error(kind, details)
    case kind
    when :forbidden
      [403, { error: { code: 'forbidden', message: 'Forbidden', details: details } }]
    when :not_found
      [404, { error: { code: 'not_found', message: 'Payment not found' } }]
    else
      [422, { error: { code: 'validation_error', message: 'Invalid payment', details: details } }]
    end
  end
end
