# frozen_string_literal: true

# Wompi configuration (sandbox-first, mocked until keys exist).
# See assistant/decisions.md ADR-005.

module WompiConfig
  def self.public_key
    ENV['WOMPI_PUBLIC_KEY']
  end

  def self.private_key
    ENV['WOMPI_PRIVATE_KEY']
  end

  def self.sandbox?
    ENV.fetch('WOMPI_SANDBOX', 'true') == 'true'
  end

  def self.configured?
    !(public_key.nil? || public_key.empty?) &&
      !(private_key.nil? || private_key.empty?)
  end

  # Mocked mode when keys are missing (P0-P3 default).
  def self.mocked?
    !configured?
  end
end
