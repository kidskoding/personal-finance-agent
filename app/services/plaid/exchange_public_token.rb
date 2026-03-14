module Plaid
  class ExchangePublicToken
    def initialize(user:, public_token:)
      @user = user
      @public_token = public_token
    end

    def call
      response = plaid_client.exchange_public_token(public_token: @public_token)

      plaid_item = PlaidItem.find_or_initialize_by(plaid_item_id: response.item_id)
      plaid_item.assign_attributes(
        user: @user,
        access_token_encrypted: encrypt(response.access_token)
      )
      plaid_item.save!

      SyncTransactionsJob.perform_later(plaid_item.id)

      plaid_item
    end

    private

    def plaid_client
      @plaid_client ||= Integrations::PlaidClient.new
    end

    def encrypt(value)
      encryptor.encrypt_and_sign(value)
    end

    def encryptor
      key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base)
                                       .generate_key("plaid_access_token", 32)
      ActiveSupport::MessageEncryptor.new(key)
    end
  end
end
