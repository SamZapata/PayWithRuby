# frozen_string_literal: true

# Payments table (P4). One payment per completed ride (ride_id UNIQUE).
# Status machine: pending -> approved / declined (via webhook).
# idempotency_key UNIQUE guards double-charge retries / race.
# FK RESTRICT preserves history (ADR-009 pattern).

Sequel.migration do
  change do
    create_table(:payments) do
      primary_key :id
      foreign_key :ride_id, :rides, null: false, unique: true, on_delete: :restrict
      Integer :amount, null: false
      String :status, null: false, default: 'pending', size: 20
      String :wompi_transaction_id, null: true, unique: true, size: 100
      String :idempotency_key, null: false, unique: true, size: 100
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      index :ride_id
      index :status
      index :wompi_transaction_id
      index :idempotency_key
    end
  end
end
