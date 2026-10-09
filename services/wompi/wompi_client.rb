# frozen_string_literal: true

require 'securerandom'
require_relative '../../config/wompi'

# Wompi payment gateway client (sandbox-first, mocked until keys exist).
# See assistant/decisions.md ADR-005 and ADR-010.
#
# Stable interface so swapping mock -> sandbox requires config only:
#   WompiClient.charge(amount:, ride_id:, idempotency_key:)
#     -> { transaction_id:, status: 'pending' }
#
# Mocked mode (default in P4): returns canned pending response with
# an unguessable transaction id. Sandbox branch is stubbed for P4+.

module WompiClient
  def self.charge(amount:, ride_id:, idempotency_key:)
    return mock_charge(amount: amount, ride_id: ride_id, idempotency_key: idempotency_key) if WompiConfig.mocked?

    sandbox_charge(amount: amount, ride_id: ride_id, idempotency_key: idempotency_key)
  end

  def self.mock_charge(amount:, ride_id:, idempotency_key:)
    {
      transaction_id: "mock-#{SecureRandom.uuid}",
      status: 'pending',
      amount: amount,
      ride_id: ride_id,
      idempotency_key: idempotency_key
    }
  end

  # Sandbox implementation lands when real keys are configured.
  # Keep the same return shape as mock_charge.
  def self.sandbox_charge(amount:, ride_id:, idempotency_key:)
    raise NotImplementedError,
          'Wompi sandbox charge not implemented yet. Set WOMPI_PUBLIC_KEY/WOMPI_PRIVATE_KEY and implement sandbox_charge (same return shape as mock_charge).'
  end
end
