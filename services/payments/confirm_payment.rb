# frozen_string_literal: true

# Business operation: confirm a pending payment via Wompi webhook.
# Public caller (no current_user): trust comes from the unguessable
# transaction id in P4; signature verification is a sandbox follow-up.
# Only pending -> approved/declined. Replaying the same terminal status
# is idempotent. Returns [:ok, payment] or [:error, kind, details].

module Payments
  module ConfirmPayment
    TERMINAL = %w[approved declined].freeze

    def self.call(transaction_id:, status:)
      return [:error, :invalid, { status: 'must be one of: approved, declined' }] unless TERMINAL.include?(status.to_s)

      payment = PaymentRepository.find_by_transaction(transaction_id.to_s)
      return [:error, :not_found, { transaction: 'not found' }] if payment.nil?

      return [:ok, payment] if payment.status == status.to_s
      return [:error, :invalid, { status: 'payment is already finalized' }] unless payment.status == 'pending'

      updated = PaymentRepository.update(payment.id, status: status.to_s)
      [:ok, updated]
    rescue Sequel::ValidationFailed => e
      [:error, :invalid, { base: e.message }]
    end
  end
end
