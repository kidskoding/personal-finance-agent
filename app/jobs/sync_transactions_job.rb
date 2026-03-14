class SyncTransactionsJob < ApplicationJob
  queue_as :default

  def perform(plaid_item_id)
    plaid_item = PlaidItem.find(plaid_item_id)
    Plaid::SyncTransactions.new(plaid_item).call
  end
end
