# frozen_string_literal: true

# Tighten varchar sizes (was all varchar(255) by Sequel default).
# Riders/drivers: name 100, email 255, phone 30, status 20.
# Drivers extra: license_plate 20, vehicle_model 100.

Sequel.migration do
  change do
    alter_table(:riders) do
      set_column_type :name, String, size: 100
      set_column_type :email, String, size: 255
      set_column_type :phone, String, size: 30
      set_column_type :status, String, size: 20
    end

    alter_table(:drivers) do
      set_column_type :name, String, size: 100
      set_column_type :email, String, size: 255
      set_column_type :phone, String, size: 30
      set_column_type :license_plate, String, size: 20
      set_column_type :vehicle_model, String, size: 100
      set_column_type :status, String, size: 20
    end
  end
end
