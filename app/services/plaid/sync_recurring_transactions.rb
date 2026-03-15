module Plaid
  class SyncRecurringTransactions
    FREQUENCY_MAP = {
      "WEEKLY"       => "weekly",
      "BIWEEKLY"     => "weekly",
      "SEMI_MONTHLY" => "monthly",
      "MONTHLY"      => "monthly",
      "ANNUALLY"     => "annual"
    }.freeze

    def initialize(plaid_item)
      @plaid_item = plaid_item
      @user = plaid_item.user
    end

    def call
      response = plaid_client.recurring_transactions(access_token: access_token)
      persist(response.outflow_streams)
    end

    private

    def plaid_client
      @plaid_client ||= Integrations::PlaidClient.new
    end

    def access_token
      @access_token ||= TokenEncryptor.decrypt(@plaid_item.access_token_encrypted)
    end

    def persist(streams)
      active_names = []

      streams.each do |stream|
        next unless stream.is_active
        next unless FREQUENCY_MAP.key?(stream.frequency)

        cadence = FREQUENCY_MAP[stream.frequency]
        name    = stream.merchant_name.presence || stream.description
        amount  = stream.last_amount&.amount || stream.average_amount&.amount
        next unless name && amount

        record = RecurringCharge.find_or_initialize_by(user: @user, merchant_name: name)
        record.assign_attributes(
          amount: amount.abs,
          cadence: cadence,
          last_charged_on: stream.last_date,
          active: true
        )
        record.save!
        active_names << name
      end

      # Mark charges no longer in Plaid's streams as inactive
      @user.recurring_charges.where.not(merchant_name: active_names).update_all(active: false)
    end
  end
end
