# frozen_string_literal: true

# Persistence isolation for payments. Encapsulates Sequel queries.
# Justified by idempotency seams: lookups by ride / transaction / key.
# No business logic, no HTTP. Returns Sequel models (or nil).

class PaymentRepository
  def self.all(status: nil, ride_id: nil)
    ds = Payment.order(:id)
    ds = ds.where(status: status.to_s) unless status.nil? || status.to_s.empty?
    ds = ds.where(ride_id: ride_id) unless ride_id.nil? || ride_id.to_s.empty?
    ds.all
  end

  def self.find(id)
    Payment[id]
  end

  def self.find_by_ride(ride_id)
    Payment.where(ride_id: ride_id).first
  end

  def self.find_by_transaction(transaction_id)
    Payment.where(wompi_transaction_id: transaction_id.to_s).first
  end

  def self.find_by_idempotency_key(key)
    Payment.where(idempotency_key: key.to_s).first
  end

  def self.create(attrs)
    Payment.create(symbolize(attrs))
  end

  def self.update(id, attrs)
    payment = find(id)
    return nil if payment.nil?

    payment.update(symbolize(attrs))
    payment.refresh
  end

  def self.symbolize(hash)
    hash.transform_keys(&:to_sym)
  end
end
