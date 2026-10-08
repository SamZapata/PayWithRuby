# frozen_string_literal: true

# Rides lifecycle table (P3).
# driver_id NULL until accepted. Price in COP pesos (integer, >= 0).
# Status machine: requested -> accepted -> completed / cancelled.
# FKs RESTRICT + soft-delete on riders/drivers preserves history (ADR-009).

Sequel.migration do
  change do
    create_table(:rides) do
      primary_key :id
      foreign_key :rider_id, :riders, null: false, on_delete: :restrict
      foreign_key :driver_id, :drivers, null: true, on_delete: :restrict
      String :origin, null: false, size: 255
      String :destination, null: false, size: 255
      Integer :price, null: false
      String :status, null: false, default: 'requested', size: 20
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      index :rider_id
      index :driver_id
      index :status
    end
  end
end
