# frozen_string_literal: true

# JSON presentation for payments. Formatting only, no logic.

module PaymentSerializer
  def self.to_h(payment)
    {
      id: payment.id,
      ride_id: payment.ride_id,
      amount: payment.amount,
      status: payment.status,
      wompi_transaction_id: payment.wompi_transaction_id,
      idempotency_key: payment.idempotency_key,
      created_at: payment.created_at&.utc&.iso8601,
      updated_at: payment.updated_at&.utc&.iso8601
    }
  end

  def self.list_to_h(payments)
    payments.map { |p| to_h(p) }
  end
end
