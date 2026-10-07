# frozen_string_literal: true

# JSON presentation for users. Formatting only, no logic.
# Never includes password_hash.

module UserSerializer
  def self.to_h(user)
    {
      id: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
      created_at: user.created_at&.utc&.iso8601,
      updated_at: user.updated_at&.utc&.iso8601
    }
  end
end
