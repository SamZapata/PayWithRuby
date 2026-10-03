# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:drivers) do
      primary_key :id
      String :name, null: false
      String :email, null: false, unique: true
      String :phone
      String :license_plate, null: false, unique: true
      String :vehicle_model
      String :status, null: false, default: 'active'
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
