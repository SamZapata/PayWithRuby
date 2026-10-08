# frozen_string_literal: true

# JSON presentation for drivers. Formatting only, no logic.

module DriverSerializer
  def self.to_h(driver)
    {
      id: driver.id,
      user_id: driver.user_id,
      name: driver.name,
      email: driver.email,
      phone: driver.phone,
      license_plate: driver.license_plate,
      vehicle_model: driver.vehicle_model,
      status: driver.status,
      created_at: driver.created_at&.utc&.iso8601,
      updated_at: driver.updated_at&.utc&.iso8601
    }
  end

  def self.list_to_h(drivers)
    drivers.map { |d| to_h(d) }
  end
end
