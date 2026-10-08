# frozen_string_literal: true

# JSON presentation for riders. Formatting only, no logic.

module RiderSerializer
  def self.to_h(rider)
    {
      id: rider.id,
      user_id: rider.user_id,
      name: rider.name,
      email: rider.email,
      phone: rider.phone,
      status: rider.status,
      created_at: rider.created_at&.utc&.iso8601,
      updated_at: rider.updated_at&.utc&.iso8601
    }
  end

  def self.list_to_h(riders)
    riders.map { |r| to_h(r) }
  end
end
